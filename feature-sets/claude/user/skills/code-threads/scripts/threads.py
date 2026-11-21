#!/usr/bin/env python3
"""Writes and reads comment threads on code, for the CodeReview.json extension of VS Code.

    threads.py use <review>
    threads.py add <file> <start> [<end>] <body> [--author <name>]
    threads.py reply <thread> <body> [--author <name>]
    threads.py resolve <thread>
    threads.py reopen <thread>
    threads.py list [--all] [--json]

Each command takes `--review <name>`.

Without `--review`, a command acts on the active review.

A review is the log `.review/<review>.log.jsonl` at the workspace root, one event per line. The
extension and this script only append to the log, so neither overwrites the other.

The extension builds the threads from the log, and it shows only the active review, the one in
`.review/state.json`.

A body of `-` reads the text from stdin.

`list` shows the threads that wait for us: the last comment is not ours, or the last event is a
reopen. `--all` shows every thread.

`list --json` prints the same threads as a JSON list, with the fields of `Review.threads`.
"""

import argparse
import datetime
import json
import os
import random
import subprocess
import sys
from pathlib import Path

AGENT = "agent"


def main():
    args = Cli.parse()
    review = Review.open(args.root, args.review)

    if args.command == "use":
        review.activate()
        print(f"active: {review.name}")
    elif args.command == "add":
        body = Cli.body(args.body)
        end = args.end if args.end is not None else args.start
        thread = review.add(args.file, args.start, end, body, args.author)
        print(thread)
    elif args.command == "reply":
        review.append({"op": "reply", "thread": args.thread, "author": args.author, "body": Cli.body(args.body)})
    elif args.command in ("resolve", "reopen"):
        review.append({"op": args.command, "thread": args.thread})
    else:
        review.print_threads(args.all, args.json)


class Cli:
    """The command line."""

    @staticmethod
    def parse():
        parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
        parser.add_argument("--root", help="the workspace root (default: the root of the git repository)")
        parser.add_argument("--review", help="the review to act on (default: the active review)")
        sub = parser.add_subparsers(dest="command", required=True)

        use = sub.add_parser("use")
        use.add_argument("name")

        add = sub.add_parser("add")
        add.add_argument("file")
        add.add_argument("start", type=int)
        add.add_argument("end", type=int, nargs="?")
        add.add_argument("body")
        add.add_argument("--author", default=AGENT)

        reply = sub.add_parser("reply")
        reply.add_argument("thread")
        reply.add_argument("body")
        reply.add_argument("--author", default=AGENT)

        for command in ("resolve", "reopen"):
            sub.add_parser(command).add_argument("thread")

        list_ = sub.add_parser("list")
        list_.add_argument("--all", action="store_true")
        list_.add_argument("--json", action="store_true", help="print the threads as a JSON list")

        # `use` names the review itself.
        args = parser.parse_args()
        if args.command == "use":
            args.review = args.name
        return args

    @staticmethod
    def body(text):
        """Returns `text`, or the text on stdin if `text` is `-`."""
        if text == "-":
            return sys.stdin.read().rstrip("\n")
        return text


class Review:
    """One review log in the `.review` folder of the workspace."""

    def __init__(self, root, name):
        self.root = root
        self.dir = root / ".review"
        self.name = name

    @staticmethod
    def open(root, name):
        # The workspace root: given, or the root of the git repository.
        if root:
            root = Path(root).resolve()
        else:
            out = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True)
            root = Path(out.stdout.strip())

        # The review: given, or the active one.
        if not name:
            state = root / ".review" / "state.json"
            name = json.loads(state.read_text()).get("active") if state.exists() else None
        if not name:
            sys.exit("no active review: run `threads.py use <review>` first")

        # The extension joins the name into a path, so keep it to one plain file name.
        if "/" in name or name.startswith("."):
            sys.exit(f"not a valid review name: {name}")
        return Review(root, name)

    @property
    def log(self):
        return self.dir / f"{self.name}.log.jsonl"

    def activate(self):
        """Makes this review the one that the extension shows, and creates its log."""
        self.dir.mkdir(exist_ok=True)
        self.log.touch()
        state = self.dir / "state.json"
        tmp = state.with_suffix(".json.tmp")
        tmp.write_text(json.dumps({"active": self.name}, indent=2))
        os.replace(tmp, state)

    def add(self, file, start, end, body, author, thread=None):
        """Opens a thread on lines `start` to `end` of `file`, and returns its ID.

        Without `thread`, the thread gets a random ID.
        """
        # The path relative to the workspace root, as the extension stores it.
        path = Path(file)
        path = path.resolve() if path.is_absolute() else (Path.cwd() / path).resolve()
        rel = path.relative_to(self.root).as_posix()

        # The snapshot anchors the thread: the extension finds it again when the code moves.
        lines = path.read_text().split("\n")
        if not 1 <= start <= end <= len(lines):
            sys.exit(f"{rel} has no lines {start} to {end}")
        snapshot = "\n".join(lines[start - 1 : end])

        thread = thread or "t_" + "".join(random.choices("0123456789abcdefghijklmnopqrstuvwxyz", k=7))
        self.append(
            {
                "op": "add_thread",
                "id": thread,
                "file": rel,
                "range": {"startLine": start, "endLine": end},
                "snapshot": snapshot,
                "author": author,
                "body": body,
            }
        )
        return thread

    def append(self, event):
        """Appends `event` to the log, with the current time."""
        event["ts"] = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        self.dir.mkdir(exist_ok=True)
        with self.log.open("a") as f:
            f.write(json.dumps(event) + "\n")

    def threads(self):
        """Builds the threads from the log, the way the extension does."""
        threads = {}
        lines = self.log.read_text().splitlines() if self.log.exists() else []
        for line in lines:
            # The extension also skips a line that does not parse.
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue

            op = event.get("op")
            if op == "add_thread":
                comment = {"id": f"{event['id']}.c1", "author": event["author"], "body": event["body"]}
                threads[event["id"]] = {
                    "id": event["id"],
                    "file": event["file"],
                    "range": event["range"],
                    "status": "open",
                    "waiting": event["author"] != AGENT,
                    "comments": [comment],
                }
                continue

            thread = threads.get(event.get("thread") or event.get("comment", "").rsplit(".c", 1)[0])
            if thread is None:
                continue

            # A thread waits for us after a comment of someone else, or after a reopen, until we
            # answer or someone resolves it.
            if op == "reply":
                comment_id = f"{thread['id']}.c{len(thread['comments']) + 1}"
                thread["comments"].append({"id": comment_id, "author": event["author"], "body": event["body"]})
                thread["waiting"] = event["author"] != AGENT
            elif op == "resolve":
                thread["status"] = "resolved"
                thread["waiting"] = False
            elif op == "reopen":
                thread["status"] = "open"
                thread["waiting"] = True
            elif op == "edit_comment":
                for comment in thread["comments"]:
                    if comment["id"] == event["comment"]:
                        comment["body"] = event["body"]

        return list(threads.values())

    def print_threads(self, show_all, as_json=False):
        threads = [t for t in self.threads() if show_all or t["waiting"]]
        if as_json:
            print(json.dumps(threads, indent=2, ensure_ascii=False))
            return

        for thread in threads:
            waiting = thread["waiting"]
            where = f"{thread['file']}:{thread['range']['startLine']}"
            marker = " (waits for us)" if waiting else ""
            print(f"## {thread['id']} [{thread['status']}] {where}{marker}")
            for comment in thread["comments"]:
                print(f"- {comment['author']}: {comment['body']}")
            print()


if __name__ == "__main__":
    main()
