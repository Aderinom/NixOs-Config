---
name: layout-review
description: Find function bodies that break the code layout rules (thoughts, blank lines, thought comments, returned match or if, helper placement) and fix them in place. Use when the user asks to review, clean up, or fix the layout of a function, file, diff, branch, commit, or PR.
---

# Layout review

Find function bodies that are hard to scan. Fix the layout. Keep every
behavior.

## Rules

Read `~/.claude/rules/code-layout.md` and apply every rule in it. Write
each new comment by `~/.claude/rules/writing.md`.

## Scope

- Change layout only: blank lines, thought comments, bindings before a
  return, and helper placement.
- Do not change behavior, names, or public signatures.
- Do not fight the formatter of the project. If rustfmt, Prettier, gofmt, or
  a linter decides a point, follow it.
- If the project rules differ from these rules, follow the project rules.
- If the user gives a file or diff, change only the functions in it.
- If the user names a diff, a branch, a commit, or a PR, load the
  `diff-target` skill to find the change. Change only the functions that
  the change adds or edits.

## Helpers

- Before you move a helper, check its callers with a search. A test or a
  second module can also call it.
- If the language cannot nest a function, leave the helper where it is.

## Verify

After the fixes, run the formatter and the tests of the touched package. If
the formatter undoes a fix, keep the formatter output.

## Output

Fix every finding in place. Do not ask first.

Report the fixes as a short list, grouped by rule, with file links. Name any
finding that you did not fix, and the reason.

If the code already follows the rules, say so in one sentence.
