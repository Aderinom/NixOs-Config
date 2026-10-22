---
name: text-review
description: Find AI-sounding text in prose, docs, or code comments and fix it in place into plain human speech. Use when the user asks to review, clean up, simplify, or "de-AI" a document, README, comment, commit message, or PR text.
---

# Plain review

Find text that sounds like an AI wrote it. Rewrite it the way a colleague
talks. Keep every fact.

## Rules

Read `~/.claude/rules/writing.md` and apply every rule in it.

## Scope

- Change prose only: docs, comments, commit messages, PR text, chat drafts.
- Leave code, commands, paths, identifiers, and error messages byte-exact.
- If the user gives a file or diff, change only the prose in it.
- If the user names a diff, a branch, a commit, or a PR, or names no
  target, load the `diff-target` skill to find the change.

## Output

Fix every finding in place. Do not ask first.

If the text already follows the rules, say so in one sentence.
