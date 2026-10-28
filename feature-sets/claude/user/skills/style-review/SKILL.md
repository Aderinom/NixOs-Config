---
name: style-review
description: Fix the layout of function bodies and the prose of comments and docs in one pass, in place. Use when the user asks for a style review, a cleanup before a commit, or both a layout and a text review.
---

# Style review

Run the `layout-review` and the `text-review` skills on one target, in
that order. Fix every finding in place. Do not ask first.

## Target

Load the `diff-target` skill. Find the target once, and give the same
files to both passes.

## Order

1. Layout first. It adds thought comments and moves helpers.
2. Text second. It then also checks the comments from step 1.

Each pass follows the Scope and Rules of its own skill.

## Verify

Run the formatter and the tests of the touched packages once, after
both passes.

## Output

One report with two groups, Layout and Text. Each group is a short list of
fixes with file links. Name any finding that you did not fix, and the
reason. If a group has no finding, say so in one sentence.
