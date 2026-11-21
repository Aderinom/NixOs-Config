#!/usr/bin/env python3
"""Writes REVIEW.md from the code threads of a peer review, and reads it back for the publish.

    review_md.py build --pr <n> --topic <id>=<text> ... [--blocking <id>,...] [--dry-run]
    review_md.py parse

The model is a `Review` with one `Comment` per open thread.

`build` reads the threads into the
model and serializes it to Markdown. `parse` reads the Markdown into the same model and serializes
it to the publish payloads.

`build` reads the open threads of the review `<branch>-review` with `threads.py list --json` of
the `code-threads` skill. With `--dry-run`, it prints the Markdown and writes no file.

The comment text of a thread is the last comment of the user. A thread with a comment of the user
gets the source `user`.

If the user wrote nothing in the thread, the comment text is the first comment of the agent.

`--blocking` sets the state `blocking` for the listed threads. All other threads get
`discussing`.

`--topic` sets the topic of a thread. Each open thread needs one, and `build` stops if one is
missing.

`parse` prints a JSON object with the payloads and the GitHub state that their dispositions give.
Each payload holds the path, the line, the disposition, and the body to send.

`parse` changes nothing, so it needs no dry run.

If the table and a `State:` line disagree, `parse` stops with an error.

Each command takes `--file <path>`. `build` also takes `--review <name>` and `--root <path>`.

The default file is `_local/<branch>/REVIEW.md` at the repository root.
"""

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

# The log of the code threads belongs to the `code-threads` skill, so this script reads it only
# through the command line of that skill.
THREADS = Path(__file__).resolve().parents[2] / "code-threads" / "scripts" / "threads.py"
AGENT = "agent"
BLOCKING = "blocking"
DISCUSSING = "discussing"
FENCE_LANGUAGES = {
    ".rs": "rust",
    ".go": "go",
    ".py": "python",
    ".ts": "ts",
    ".tsx": "tsx",
    ".js": "js",
    ".toml": "toml",
    ".yml": "yaml",
    ".yaml": "yaml",
    ".json": "json",
    ".sh": "bash",
    ".nix": "nix",
    ".md": "markdown",
}


def main():
    args = Cli.parse()
    root = Path(args.root).resolve() if args.root else Repo.root()
    path = Path(args.file) if args.file else root / "_local" / Repo.branch() / "REVIEW.md"

    if args.command == "parse":
        review = Review.from_markdown(path.read_text())
        print(json.dumps(review.to_payloads(), indent=2, ensure_ascii=False))
        return

    # Build the model from the threads, and serialize it to Markdown.
    threads = Threads.read(root, args.review or f"{Repo.branch()}-review")
    review = Review.from_threads(args.pr, threads, root, args.blocking, args.topic)
    text = review.to_markdown()
    if args.dry_run:
        print(text, end="")
        return

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    print(f"{path}: {len(review.comments)} comments")


@dataclass
class Review:
    """The review of one pull request: the comments in the order of their keys."""

    pr: int
    comments: list = field(default_factory=list)

    @staticmethod
    def from_threads(pr, threads, root, blocking, topics):
        """Returns the review of the open `threads`, with the blocking comments first."""
        threads = [t for t in threads if t["status"] == "open"]

        # Stop on an ID that names no open thread, because a typo would lose a blocking state.
        ids = {t["id"] for t in threads}
        unknown = (blocking | topics.keys()) - ids
        if unknown:
            sys.exit(f"no open thread has the ID: {', '.join(sorted(unknown))}")

        # Stop if a thread has no topic, because the first words of a comment make a poor topic.
        missing = ids - topics.keys()
        if missing:
            sys.exit(f"give a --topic for: {', '.join(sorted(missing))}")

        # Order the comments, then number them in that order.
        comments = [Comment.from_thread(t, root, t["id"] in blocking, topics[t["id"]]) for t in threads]
        comments.sort(key=lambda c: (c.state != BLOCKING, c.path, c.line))
        for number, comment in enumerate(comments, 1):
            comment.key = f"C{number}"
        return Review(pr, comments)

    @staticmethod
    def from_markdown(text):
        """Returns the review in `text`, or stops if a state disagrees with the table."""
        lines = text.split("\n")
        pr = next((int(m.group(1)) for m in map(Markdown.TITLE.match, lines) if m), 0)
        table = {m.group(1): m for m in map(Markdown.ROW.match, lines) if m}
        comments = [Comment.from_section(chunk, table) for chunk in Markdown.sections(lines)]

        # Each comment needs one state, so the table and the `State:` line must agree.
        errors = [
            f"{c.key}: the table says {table[c.key].group(3) if c.key in table else None}, the State line says {c.state}"
            for c in comments
            if c.key not in table or table[c.key].group(3) != c.state
        ]
        if errors:
            sys.exit("\n".join(errors))
        return Review(pr, comments)

    def github_state(self):
        """Returns the state of the GitHub review that the dispositions give."""
        blocking = any(c.state == BLOCKING for c in self.comments)
        return "CHANGES_REQUESTED" if blocking else "COMMENTED"

    def to_payloads(self):
        """Returns the input of `review_discussions_create` for each comment, and the GitHub state."""
        payloads = [
            {"key": c.key, "path": c.path, "line": c.line, "disposition": c.state, "body": c.body}
            for c in self.comments
        ]
        return {"github_state": self.github_state(), "comments": payloads}

    def to_markdown(self):
        """Returns the text of REVIEW.md."""
        # The head and the table.
        parts = ["<!-- markdownlint-disable MD013 -->", "", f"# Review of PR #{self.pr}", ""]
        header = ["#", "Where", "Topic", "Source", "State"]
        rows = [[f"[{c.key}]", c.where(), c.topic, c.source, c.state] for c in self.comments]
        parts += Markdown.table(header, rows)

        # One section per comment.
        for comment in self.comments:
            parts += ["", f"## {comment.heading()}", "", f"State: `{comment.state}`", ""]
            parts += [f"`{comment.path}`", ""]
            if comment.code.strip():
                parts += Markdown.fence(comment.path, comment.code) + [""]
            parts.append(comment.body)

        # The link targets of the table.
        parts += ["", "<!-- Links -->", ""]
        parts += [f"[{c.key}]: #{Markdown.slug(c.heading())}" for c in self.comments]
        return "\n".join(parts) + "\n"


@dataclass
class Comment:
    """One comment of the review, on one line of one file."""

    key: str
    path: str
    line: int
    state: str
    topic: str
    source: str
    body: str
    code: str = ""

    @staticmethod
    def from_thread(thread, root, blocking, topic):
        """Returns the comment of one thread. The caller sets its key."""
        # The user's last comment replaces the text of the agent.
        by_user = [c for c in thread["comments"] if c["author"] != AGENT]
        body = by_user[-1]["body"] if by_user else thread["comments"][0]["body"]

        start, end = thread["range"]["startLine"], thread["range"]["endLine"]
        return Comment(
            key="",
            path=thread["file"],
            line=start,
            state=BLOCKING if blocking else DISCUSSING,
            topic=topic.replace("|", "/"),
            source="user" if by_user else "ai",
            body=body.strip(),
            code=Threads.code(root / thread["file"], start, end),
        )

    @staticmethod
    def from_section(chunk, table):
        """Returns the comment of one Markdown section. The source comes from the table."""
        key, line, topic = Markdown.HEADING.match(chunk[0]).group(1, 3, 4)
        rest = chunk[1:]

        # The State line and the path come first, then the optional code block.
        state, path = None, None
        while rest and (not rest[0].strip() or Markdown.STATE.match(rest[0]) or Markdown.PATH.match(rest[0])):
            head = rest.pop(0)
            if m := Markdown.STATE.match(head):
                state = m.group(1)
            elif m := Markdown.PATH.match(head):
                path = m.group(1)

        code, rest = Markdown.split_fence(rest)
        if not state or not path:
            sys.exit(f"{key}: the section needs a State line and a path line")

        source = table[key].group(2) if key in table else ""
        body = "\n".join(rest).strip()
        return Comment(key, path, int(line), state, topic, source, body, code)

    def where(self):
        return f"{Path(self.path).name}:{self.line}"

    def heading(self):
        return f"{self.key}. {self.where()}: {self.topic}"


class Markdown:
    """The parts of the Markdown format of REVIEW.md."""

    TITLE = re.compile(r"^# Review of PR #(\d+)$")
    HEADING = re.compile(r"^## (C\d+)\. (.+?):(\d+): (.*)$")
    ROW = re.compile(r"^\| \[(C\d+)\]\s*\|.*\|\s*(\w+)\s*\|\s*(\w+)\s*\|$")
    STATE = re.compile(r"^State: `(\w+)`$")
    PATH = re.compile(r"^`([^`]+)`$")

    @staticmethod
    def table(header, rows):
        """Returns the lines of a table, with each column padded to its width."""
        widths = [max(len(row[i]) for row in [header, *rows]) for i in range(len(header))]

        def line(cells):
            return "| " + " | ".join(cell.ljust(width) for cell, width in zip(cells, widths)) + " |"

        return [line(header), line(["-" * width for width in widths])] + [line(row) for row in rows]

    @staticmethod
    def fence(path, code):
        """Returns the lines of a code block, with a fence longer than any backtick run in `code`."""
        longest = max((len(run) for run in re.findall(r"`+", code)), default=0)
        ticks = "`" * max(3, longest + 1)
        language = FENCE_LANGUAGES.get(Path(path).suffix, "")
        return [f"{ticks}{language}", code, ticks]

    @staticmethod
    def slug(heading):
        """Returns the GitHub anchor of `heading`."""
        text = re.sub(r"[^\w\- ]", "", heading.lower())
        return text.replace(" ", "-")

    @staticmethod
    def sections(lines):
        """Yields the lines of each comment section, from its heading to the next one."""
        chunk = None
        for line in lines:
            if line.startswith("## ") or line == "<!-- Links -->":
                if chunk:
                    yield chunk
                chunk = [line] if Markdown.HEADING.match(line) else None
            elif chunk is not None:
                chunk.append(line)

        if chunk:
            yield chunk

    @staticmethod
    def split_fence(lines):
        """Returns the code of the code block at the start of `lines`, and the lines after it.

        If `lines` do not start with a code block, the code is empty.
        """
        if not lines or not (m := re.match(r"^(`{3,})", lines[0])):
            return "", lines

        ticks = m.group(1)
        for index, line in enumerate(lines[1:], 1):
            if line.strip() == ticks:
                return "\n".join(lines[1:index]), lines[index + 1 :]

        sys.exit("a code block in REVIEW.md has no closing fence")


class Threads:
    """The code threads of the `code-threads` skill."""

    @staticmethod
    def read(root, review):
        """Returns all threads of `review`, as `threads.py list --all --json` prints them."""
        command = [sys.executable, "-I", str(THREADS), "--root", str(root), "--review", review, "list", "--all", "--json"]
        out = subprocess.run(command, capture_output=True, text=True, check=True)
        return json.loads(out.stdout)

    @staticmethod
    def code(path, start, end):
        """Returns lines `start` to `end` of `path`, or an empty string if the file is gone."""
        if not path.exists():
            return ""
        lines = path.read_text().split("\n")
        return "\n".join(lines[start - 1 : end])


class Cli:
    """The command line."""

    @staticmethod
    def parse():
        parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
        parser.add_argument("--file", help="the REVIEW.md (default: _local/<branch>/REVIEW.md)")
        parser.add_argument("--root", help="the repository root (default: the root of the git repository)")
        sub = parser.add_subparsers(dest="command", required=True)

        build = sub.add_parser("build")
        build.add_argument("--pr", required=True, type=int, help="the number of the pull request")
        build.add_argument("--review", help="the review of the threads (default: <branch>-review)")
        build.add_argument("--blocking", default="", help="the IDs of the blocking threads, comma-separated")
        build.add_argument("--topic", action="append", default=[], help="<thread ID>=<topic>, repeatable")
        build.add_argument("--dry-run", action="store_true", help="print the Markdown, and write no file")

        sub.add_parser("parse")
        args = parser.parse_args()

        # Turn the lists into the forms that `build` uses.
        if args.command == "build":
            args.blocking = {id_ for id_ in args.blocking.split(",") if id_}
            args.topic = dict(Cli.pair(item) for item in args.topic)
        return args

    @staticmethod
    def pair(item):
        """Splits `<id>=<text>` into its two parts."""
        if "=" not in item:
            sys.exit(f"--topic needs <thread ID>=<topic>: {item}")
        id_, text = item.split("=", 1)
        return id_, text


class Repo:
    """The git repository of the working directory."""

    @staticmethod
    def root():
        out = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True)
        return Path(out.stdout.strip())

    @staticmethod
    def branch():
        out = subprocess.run(["git", "branch", "--show-current"], capture_output=True, text=True, check=True)
        return out.stdout.strip()


if __name__ == "__main__":
    main()
