#!/usr/bin/env python3
"""Pulls the Reviewable discussions of a pull request into REVIEW.md, and posts the replies back.

    review.py pull <owner/repo/pr> [--file <path>]
    review.py post <owner/repo/pr> [--file <path>]

`pull` writes one section per discussion: the comments, then a reply block.

On a second run, `pull` keeps the R numbers, the topics, and each reply that is not sent yet.

`post` sends each written reply as a draft with its disposition, then compares the drafts in
Reviewable with the file.

`post` never publishes.

The default file is `_local/<branch>/REVIEW.md` at the repository root.

It runs the `reviewable` CLI, or `npx -y reviewable@latest` if that is not on PATH. The CLI needs
`REVIEWABLE_API_TOKEN`.

If the variable is missing, or if the CLI rejects its token, the script takes the token of the
`reviewable` MCP server in `~/.claude.json`.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

RULE = "-" * 67
LINT = "<!-- markdownlint-disable MD013 MD035 -->"
LINKS = "<!-- Links -->"
OPEN = "`OPEN`"
NO_REPLY = "`NO REPLY`"
MARKERS = (OPEN, NO_REPLY)

SECTION = re.compile(r"^## R(\d+)\. (.*)$", re.M)
THREAD_DEF = re.compile(r"^\[R(\d+) thread\]: \S+#(\S+)$", re.M)
REPLY = re.compile(r"^### Reply \[([a-z]+)\]\n\n(.*?)(?=\n\n" + RULE + r"\n|\n\n" + LINKS + ")", re.S | re.M)


# TODO: Each call starts the CLI again through Node, which takes seconds. A pull of 10 threads
# takes about 18 seconds. For reviews with many threads, start `reviewable mcp` once, and send
# the requests to it over stdio.
class Cli:
    """Runs the Reviewable CLI for one pull request."""

    def __init__(self, pr):
        self.pr = pr
        self.env = dict(os.environ)
        self.env.setdefault("REVIEWABLE_URL", "https://reviewable.io")
        self.token_from_mcp = "REVIEWABLE_API_TOKEN" not in self.env
        if self.token_from_mcp:
            self.env["REVIEWABLE_API_TOKEN"] = Cli.mcp_token()
        npx = ["npx", "-y", "--prefer-offline", "reviewable@latest"]
        self.command = ["reviewable"] if shutil.which("reviewable") else npx

    def run(self, *args, stdin=None, with_pr=True):
        """Runs one CLI command and returns its JSON output."""
        pr_arg = [f"--pr={self.pr}"] if with_pr else []
        result = subprocess.run(
            [*self.command, *args, *pr_arg],
            input=stdin,
            capture_output=True,
            text=True,
            env=self.env,
        )
        output = json.loads(result.stdout or "null")
        error = output.get("error") if isinstance(output, dict) and output.get("ok") is False else None

        # If the CLI rejects the token from the environment, retry once with the token of the MCP
        # server, because the environment can hold an old token.
        if error and error.get("code") == "invalid_agent_token" and not self.token_from_mcp:
            self.env["REVIEWABLE_API_TOKEN"] = Cli.mcp_token()
            self.token_from_mcp = True
            return self.run(*args, stdin=stdin, with_pr=with_pr)

        # The CLI reports a failure as an object with `ok: false`.
        if result.returncode != 0 or error:
            sys.exit(f"reviewable {' '.join(args)} failed: {error or result.stderr}")

        return output

    def whoami(self):
        return self.run("whoami", with_pr=False)

    def discussions(self, query=None):
        args = ["review", "discussions", "list"] + ([f"--query={query}"] if query else [])
        keys = self.run(*args)

        # Each call starts the CLI again, which takes seconds, so the views run in parallel.
        with ThreadPoolExecutor(max_workers=8) as pool:
            return list(pool.map(lambda key: self.run("review", "discussions", "view", f"--key={key}"), keys))

    def reply(self, key, body, disposition):
        payload = json.dumps({"markdownBody": body, "disposition": disposition})
        self.run("review", "discussions", "reply", f"--key={key}", stdin=payload)

    @staticmethod
    def mcp_token():
        """Returns the token of the `reviewable` MCP server in `~/.claude.json`."""
        config = json.loads((Path.home() / ".claude.json").read_text())
        stack = [config]
        while stack:
            node = stack.pop()
            if isinstance(node, dict):
                server = node.get("reviewable")
                if isinstance(server, dict) and "REVIEWABLE_API_TOKEN" in server.get("env", {}):
                    return server["env"]["REVIEWABLE_API_TOKEN"]
                stack.extend(node.values())
            elif isinstance(node, list):
                stack.extend(node)
        sys.exit("REVIEWABLE_API_TOKEN is not set, and ~/.claude.json has no reviewable server")


class Thread:
    """One discussion, with its number, topic, and reply block."""

    def __init__(self, data, pr, own_keys):
        self.data = data
        self.key = data["key"]
        self.owner, self.repo, self.pr_number = pr.split("/")
        self.comments = data.get("comments", [])
        self.location = data.get("location")
        self.dispositions = {p["username"]: p.get("disposition", "") for p in data.get("participants", [])}
        self.own_keys = own_keys
        self.number = None
        self.topic = None
        self.reply_disposition = "discussing"
        self.reply = OPEN

    def where(self):
        if not self.location:
            return "review" if self.key == "-top" else "general"
        name = Path(self.location["file"]["path"]).name
        line = self.location.get("line")
        where = f"{name}:{line}" if line else name
        return where

    def sort_key(self):
        if not self.location:
            return ("", 0)
        return (self.location["file"]["path"], self.location.get("line") or 0)

    def default_topic(self):
        """Returns the start of the first comment, cut at a word."""
        first = self.comments[0]["markdownBody"] if self.comments else ""
        line = next((l for l in first.splitlines() if l.strip()), "")
        line = re.sub(r"[*_`>#]", "", line).strip()
        if len(line) <= 40:
            return line
        return line[:40].rsplit(" ", 1)[0] + " ..."

    def is_own(self, comment):
        return comment["author"].get("userKey") in self.own_keys

    def own_bodies(self):
        return {normalize(c["markdownBody"]) for c in self.comments if self.is_own(c)}

    def merge(self, old_disposition, old_reply):
        """Keeps an unsent reply from the file, or sets the marker that fits the thread."""
        if old_disposition:
            self.reply_disposition = old_disposition

        # A reply that matches a published comment of ours went out already.
        if old_reply and old_reply not in MARKERS and normalize(old_reply) not in self.own_bodies():
            self.reply = old_reply
            return

        last_is_own = bool(self.comments) and self.is_own(self.comments[-1])
        self.reply = NO_REPLY if last_is_own else OPEN

    def heading(self):
        return f"R{self.number}. {self.where()}: {self.topic}"

    def links(self, review_dir, repo_root):
        """Returns the link labels of the thread and their targets."""
        n = self.number
        links = [(f"R{n} thread", self.data.get("url") or self.thread_url())]
        if not self.location:
            return links

        # The code at the revision of the review, because the line moves in later commits.
        path = self.location["file"]["path"]
        revision = self.location.get("revision", {})
        line = self.location.get("line")
        if revision.get("commitSha"):
            anchor = f"#L{line}" if line else ""
            url = f"https://github.com/{self.owner}/{self.repo}/blob/{revision['commitSha']}/{path}{anchor}"
            links.append((f"R{n} code at review", url))

        # The local file, if it still exists at the same path.
        if (repo_root / path).exists():
            links.append((f"R{n} local file", os.path.relpath(repo_root / path, review_dir)))

        return links

    def thread_url(self):
        return f"https://reviewable.io/reviews/{self.owner}/{self.repo}/{self.pr_number}#{self.key}"

    def render(self, review_dir, repo_root):
        lines = [RULE, "", f"## {self.heading()}", ""]
        lines.append(" · ".join(f"[{label}]" for label, _ in self.links(review_dir, repo_root)))

        # Each comment: a heading, the quoted code above, then the text as a quote.
        for comment in self.comments:
            author = comment["author"]["username"]
            lines += ["", f"### {author} [{self.dispositions.get(author, 'unknown')}]"]
            for block in comment.get("codeblocks", []):
                lines += ["", f"```{block.get('language', '')}", block["originalText"], "```"]
            body = comment["markdownBody"].rstrip()
            lines += [""] + [f"> {l.rstrip()}" if l.strip() else ">" for l in body.splitlines()]

        lines += ["", f"### Reply [{self.reply_disposition}]", "", self.reply, ""]
        return "\n".join(lines)


class ReviewFile:
    """Reads and writes REVIEW.md."""

    @staticmethod
    def default_path():
        root = Path(git("rev-parse", "--show-toplevel"))
        branch = git("branch", "--show-current")
        return root / "_local" / branch / "REVIEW.md"

    @staticmethod
    def read(path):
        """Returns per discussion key: the R number, the heading, and the reply."""
        if not path.exists():
            return {}
        text = path.read_text()
        keys = {int(n): key for n, key in THREAD_DEF.findall(text)}
        entries = {}

        # Cut the file into sections, one per thread, and read each one.
        starts = [(m.start(), int(m.group(1)), m.group(2)) for m in SECTION.finditer(text)]
        for i, (start, number, heading) in enumerate(starts):
            end = starts[i + 1][0] if i + 1 < len(starts) else len(text)
            section = text[start:end]
            reply = REPLY.search(section + "\n\n" + LINKS)
            entries[keys.get(number)] = {
                "number": number,
                "heading": heading,
                "disposition": reply.group(1) if reply else None,
                "reply": reply.group(2).strip() if reply else None,
            }
        return entries

    @staticmethod
    def render(threads, pr, review_dir, repo_root):
        # The title, and the reviewers: everyone who wrote a comment that is not ours.
        owner, repo, number = pr.split("/")
        reviewers = sorted({c["author"]["username"] for t in threads for c in t.comments if not t.is_own(c)})
        lines = [LINT, "", f"# Review of PR #{number}", ""]
        lines += [f"[#{number}] · reviewers: {', '.join(reviewers) or 'none'}", ""]

        # The overview table: one row per thread, with a link to its heading.
        rows = [("#", "Where", "Topic", "Reply")]
        for t in threads:
            has_reply = t.reply not in MARKERS
            rows.append((f"[R{t.number}]", t.where(), t.topic, "+" if has_reply else ""))
        widths = [max(len(row[i]) for row in rows) for i in range(4)]
        lines.append(table_row(rows[0], widths))
        lines.append(table_row(["-" * w for w in widths], widths))
        lines += [table_row(row, widths) for row in rows[1:]]
        lines.append("")

        lines += [t.render(review_dir, repo_root) for t in threads]

        # The link definitions: the PR, the heading anchors, then the links of each thread.
        lines += [LINKS, "", f"[#{number}]: https://reviewable.io/reviews/{owner}/{repo}/{number}"]
        lines += [f"[R{t.number}]: #{slug(t.heading())}" for t in threads]
        for t in threads:
            lines += [f"[{label}]: {target}" for label, target in t.links(review_dir, repo_root)]
        return "\n".join(lines) + "\n"


def pull(args):
    cli = Cli(args.pr)
    path = Path(args.file) if args.file else ReviewFile.default_path()
    repo_root = Path(git("rev-parse", "--show-toplevel"))
    old = ReviewFile.read(path)

    # Our comments come from the agent identity or from the user behind it.
    whoami = cli.whoami()
    own_keys = {whoami["userKey"], "github:" + whoami["userKey"].split(":")[1].split("-")[0]}

    # Read every discussion. Skip the review summary if it has no comments.
    threads = []
    for data in cli.discussions():
        thread = Thread(data, args.pr, own_keys)
        if thread.comments:
            threads.append(thread)

    # Keep the numbers, topics, and unsent replies from the file. New threads get new numbers.
    next_number = max((e["number"] for e in old.values()), default=0) + 1
    for thread in sorted(threads, key=Thread.sort_key):
        entry = old.get(thread.key)
        if entry:
            thread.number = entry["number"]
            prefix = f"{thread.where()}: "
            heading = entry["heading"]
            thread.topic = heading[len(prefix):] if heading.startswith(prefix) else heading
            thread.merge(entry["disposition"], entry["reply"])
        else:
            thread.number = next_number
            next_number += 1
            thread.topic = thread.default_topic()
            thread.merge(None, None)
    threads.sort(key=lambda t: t.number)

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(ReviewFile.render(threads, args.pr, path.parent, repo_root))
    open_count = sum(t.reply == OPEN for t in threads)
    print(f"{path}: {len(threads)} threads, {open_count} open")


def post(args):
    cli = Cli(args.pr)
    path = Path(args.file) if args.file else ReviewFile.default_path()
    entries = ReviewFile.read(path)
    published = {d["key"]: d for d in cli.discussions()}

    # Send each written reply that did not go out yet.
    sent = {}
    for key, entry in sorted(entries.items(), key=lambda item: item[1]["number"]):
        reply = entry["reply"]
        if not key or not reply or reply in MARKERS:
            continue

        # A reply that matches a published comment of the thread went out already.
        posted = {normalize(c["markdownBody"]) for c in published.get(key, {}).get("comments", [])}
        if normalize(reply) in posted:
            continue

        # Post the reply as a draft, with each paragraph on one line.
        body = unwrap(reply)
        cli.reply(key, body, entry["disposition"])
        sent[key] = (body, entry["disposition"])
        print(f"R{entry['number']}: draft posted [{entry['disposition']}]")

    # Compare the drafts in Reviewable with what the file holds.
    problems = 0
    for data in cli.discussions("+draft"):
        draft = data.get("draft") or {}
        expected = sent.get(data["key"])
        if not expected:
            print(f"{data['key']}: draft that the file does not hold: {draft.get('markdownBody', '')[:60]!r}")
            problems += 1
        elif (draft.get("markdownBody"), draft.get("disposition")) != expected:
            print(f"{data['key']}: draft differs from the file")
            problems += 1
    print(f"{len(sent)} drafts posted, {problems} problems. Nothing is published.")


def unwrap(text):
    """Joins the lines of each paragraph, because GitHub keeps line breaks in comments."""
    out, fenced = [], False
    for line in text.splitlines():
        if line.startswith("```"):
            fenced = not fenced

        # A line joins the line above if both are plain prose.
        starts_block = re.match(r"\s*([-*+>|#]|\d+\.|```)", line)
        joins = out and out[-1] and line.strip() and not fenced and not starts_block and not out[-1].startswith("```")
        if joins:
            out[-1] = out[-1] + " " + line.strip()
        else:
            out.append(line)
    return "\n".join(out)


def normalize(text):
    return " ".join(text.split())


def slug(heading):
    """Returns the anchor that VS Code and GitHub give a heading."""
    text = re.sub(r"[^\w\- ]", "", heading.strip().lower())
    return text.replace(" ", "-")


def table_row(cells, widths):
    return "| " + " | ".join(c.ljust(w) for c, w in zip(cells, widths)) + " |"


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True, check=True).stdout.strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    for name, func in (("pull", pull), ("post", post)):
        command = sub.add_parser(name)
        command.add_argument("pr", help="owner/repo/number, for example Anapaya/scion/31791")
        command.add_argument("--file", help="the REVIEW.md to use")
        command.set_defaults(func=func)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
