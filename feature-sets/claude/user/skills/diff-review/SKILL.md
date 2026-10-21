---
name: diff-review
description: Review a code change for bugs and for the rules in ~/.claude/CLAUDE.md, and report findings as a ranked list. Use when the user asks to review a diff, a branch, a commit, a PR, or files.
---

# Diff review

Find what is wrong with a change. Report it. Do not fix it unless the user
asks.

## Target

- No target given: review `git diff` plus `git diff --staged`. If both are
  empty, review the current branch against its base.
- A PR number: use `gh pr diff <n>`. GitHub diffs against the PR base
  branch, so a stacked PR shows only its own commits.
- A branch or commit: diff it against its base.
- A path: review the files as they are, not a diff.

### Base

A branch can sit on top of another feature branch. Its merge base with the
main branch then pulls in the parent's commits too. So use the nearest local
branch that is an ancestor as the base:

1. List the candidates with `git for-each-ref --merged <branch> refs/heads`.
2. Drop the branch itself and any branch at the same commit.
3. Pick the one with the smallest `git rev-list --count <candidate>..<branch>`.
4. If no candidate is left, use the merge base with the main branch.

Start the output with one line that names the base branch and its commit.
The user then sees a wrong base at once.

Read the full file around each hunk. A hunk alone hides the callers, the
types, and the error paths.

## What to look for

Check in this order. Stop a pass early if it finds nothing.

1. Correctness. Wrong logic, off-by-one, unhandled error, missed edge case,
   race, resource leak, broken contract with a caller.
2. Security. Untrusted input, secrets in code or logs, unsafe defaults.
3. Tests. A new branch or a bug fix without a test that covers it.
4. Structure. Placement and names against the `code-structure` skill. Load
   it if the change adds, moves, or renames a unit.
5. Function layout, comments, and docs against `~/.claude/CLAUDE.md`
   sections "Function layout" and "Comments and documentation".
6. Simplification. Dead code, duplicate logic, an existing helper that the
   change does not use.

Follow the project rules where they differ from the global rules.

## Verify

Before you report a finding, prove it from the code:

- Name the input or state that triggers it.
- Check that no caller, guard, or type already prevents it.
- If you cannot prove it, drop it or mark it `unsure`.

Do not report style that a formatter or linter in the project already
checks.

## Output

One list, worst first. Each item:

```
<severity> <file>:<line> <one-sentence defect>
  Trigger: <input or state that causes it>
  Fix: <the concrete change>
```

Severity is one of `bug`, `risk`, `rule`, `nit`. Add `unsure` after the
severity if the Verify step did not prove it.

- Use markdown links for `<file>:<line>` so the user can click them.
- No praise. No summary of what the change does.
- If nothing survives Verify, say so in one sentence.
