---
name: code-threads
description: Put comment threads on lines of code that the user sees inline in VS Code, and read the user's replies, through the CodeReview.json extension. Use when you want to point the user at code, ask about a line, walk through a change, or report review findings, and when another skill writes review threads.
---

# Code threads

Put a comment thread on lines of code. The user sees it inline in VS Code,
replies in it, and resolves it. You read the replies from the same log.

The CodeReview.json extension (`poalrom.codereview-json`) shows the threads.

## How it works

A review is the log `.review/<review>.log.jsonl` at the workspace root, one
event per line: a new thread, a reply, a resolve, or a reopen.

The extension and the script only append to the log, so neither overwrites
the other. The extension shows new events at once.

The extension shows one review at a time: the active review in
`.review/state.json`.

## The script

```bash
python3 -I <skill folder>/scripts/threads.py <command>
```

| Command                             | Does                                                     |
| ----------------------------------- | -------------------------------------------------------- |
| `use <review>`                      | Makes the review active, and creates its log.            |
| `add <file> <start> [<end>] <body>` | Opens a thread on the lines, and prints its ID.          |
| `reply <thread> <body>`             | Adds a comment to the thread.                            |
| `resolve <thread>`                  | Resolves the thread.                                     |
| `reopen <thread>`                   | Opens the thread again.                                  |
| `list [--all]`                      | Shows the threads that wait for us, or all threads.      |

- Each command takes `--review <review>`. Without it, it acts on the
  active review.
- A body of `-` reads the text from stdin. Use stdin for a body with
  several lines or with quotes.
- `add` reads the lines of the file as the snapshot. The extension uses the
  snapshot to find the lines again when the code moves.

The docstring of the script says when a thread waits for us.

## Rules

- Name a review after the branch and the purpose, for example
  `wap-accounting-review`.
- Run `use` before the first `add` of a review, so the user sees the
  threads. Tell the user the name of the review.
- Write only through the script. Never edit or rewrite a log.
- Write each body as Markdown, by `~/.claude/rules/writing.md`.
- Your comments carry the author `agent`. Write a comment of someone else,
  for example a reviewer of a pull request, with `--author <name>`.
- The user can edit only the comments of the author `reviewer`. To correct
  a comment of yours, the user replies to it.
- Run `list` before you act on the threads, so you see each reply of the
  user.

## Setup

- The extension keeps the logs in `.review/` at the root of the first
  workspace folder. The global git ignore holds `.review/`.
- If the user has no workspace open at the repository root, pass the root
  with `--root <path>`.
