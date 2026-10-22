---
name: diff-target
description: Find the change that the user means by "the diff", a branch, a commit, a PR, or files, with the right base for a stacked branch. Use when another skill works on a change, or when the user asks what a change contains.
---

# Diff target

Find the change to work on. The skill that loads this one decides what to do
with it.

## Target

- No target given: compare the current branch with its base.
- A PR number: use `gh pr diff <n>`. GitHub diffs against the PR base
  branch, so a stacked PR shows only its own commits.
- A branch or commit: diff it against its base.
- A path: use the files as they are, not a diff.

## Base

A branch can sit on top of another feature branch. Its merge base with the
main branch then pulls in the parent's commits too. So use the nearest local
branch that is an ancestor as the base:

1. List the candidates with `git for-each-ref --merged <branch> refs/heads`.
2. Drop the branch itself and any branch at the same commit.
3. Pick the one with the smallest `git rev-list --count <candidate>..<branch>`.
4. If no candidate is left, use the merge base with the main branch.

If you diff against a base, name the base branch and its commit in the first
line of your answer. The user then sees a wrong base at once.

## Context

Read the full file around each hunk. A hunk alone hides the callers, the
types, and the error paths.
