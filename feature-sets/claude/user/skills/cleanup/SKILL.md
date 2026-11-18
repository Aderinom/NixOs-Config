---
name: cleanup
description: Fix the layout of function bodies and the prose of comments, docs, and other text, in place and without asking first. Use when the user asks for a cleanup, a style review, a layout review, or a text review, asks to "de-AI" a text, or wants a change cleaned up before a commit.
---

# Cleanup

Fix the layout of function bodies and the prose of the target. Keep every
behavior and every fact.

Fix every finding in place. Do not ask first.

## Target

Load the `diff-target` skill. Find the target once, and give the same
files to both passes.

- If the user gives a file or a diff, change only the functions and the
  prose in it.
- If the user names a diff, a branch, a commit, or a PR, change only the
  functions and the prose that the change adds or edits.

## Passes

Run both passes, in this order. The layout pass adds thought comments, and
the text pass then checks them too.

If the user asks for one pass only, for example `cleanup text README.md`,
run only that pass.

### 1. Layout

Read `~/.claude/rules/code-layout.md` and apply every rule in it. Write
each new comment by `~/.claude/rules/writing.md`.

- Change layout only: blank lines, thought comments, bindings before a
  return, and helper placement.
- Do not change behavior, names, or public signatures.
- Do not remove an assertion from a test. If an assertion looks redundant,
  report it instead.
- Before you move a helper, check its callers with a search. A test or a
  second module can also call it.
- If the language cannot nest a function, leave the helper where it is.

### 2. Text

Read `~/.claude/rules/writing.md` and apply every rule in it. Find text
that sounds like an AI wrote it, and rewrite it the way a colleague talks.

- Change prose only: docs, comments, commit messages, PR text, and chat
  drafts.
- Leave code, commands, paths, identifiers, and error messages byte-exact.

## Rules for both passes

- Do not fight the formatter of the project. If rustfmt, Prettier, gofmt,
  or a linter decides a point, follow it.
- If the project rules differ from these rules, follow the project rules.

## Verify

After the passes, run the formatter and the tests of the touched packages
once.

If the formatter undoes a fix, keep the formatter output.

## Output

One report with one group per pass, Layout and Text. Each group is a short
list of fixes with file links. Group the layout fixes by rule.

Name any finding that you did not fix, and the reason.

If a group has no finding, say so in one sentence.
