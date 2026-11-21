---
name: task-flow
description: The general flow for a task type that no skill or rule covers, such as a review for a colleague or a deploy. Holds the roles, the gates, the plan in TODO.md, and the review file for tasks with one output per input item. Use when the user gives a task and no other skill fits.
---

# Task flow

I set the goal and make the decisions. You do the work in steps, and you
stop at each gate so that I can check the result before it counts.

## Roles

- I own the goal, the names, the structure, and each go or no-go.
- You read, search, run, and draft. You check your own result before you
  show it to me.
- You give your own opinion. `CLAUDE.md` holds the rules for disagreement.

## Rules for each task

1. Find the goal and the done state. If either is not clear, ask before
   you start.
2. Write the plan to `TODO.md`, never only in chat. Split the work into
   steps. Each step ends in a result that I can check, for example a
   diff, a draft, or a command list.
3. If a result leaves this machine, write it as a local draft first.
   Examples are a PR comment, an issue, a message, and a deploy plan.
4. Before an action that others see or that is hard to undo, stop. Show
   the exact action, then wait for my go. Examples are a push, a comment,
   a deploy, and a delete.
5. Before you show a result, check it yourself. Use a review skill, a
   test, or a dry run where one exists.
6. After the task, look for repeats. If I corrected the same mistake
   twice, propose a change to a rule or a skill.

## Review files

If a task has one output for each input item, keep a review file next to
`TODO.md`. Examples are review comments that need a reply, and a diff
that needs findings.

The `review-feedback` skill and its `REVIEW.md` show the layout:

- A table at the top lists each item with its key, its place, its topic,
  and the state of its output.
- Each item has its own section: the input, with links to the code or the
  source, and the output below it.
- Each item keeps its key for the whole task, for example R1 or F1.

I read the file and edit it in the editor, so the file is the source of
truth:

- If I edit an output, keep my edit.
- Read the file again before you act on it or publish from it.
- In chat, name the items by their key.

If a task has no such list, `TODO.md` is enough.

## Examples

| Task                   | Steps                                                              | Gates                                     |
| ---------------------- | ------------------------------------------------------------------ | ----------------------------------------- |
| Review for a colleague | Read the diff. Write the findings to `REVIEW.md`. I pick and edit. | Before you publish a comment.             |
| Deploy                 | Write the commands and the rollback to `TODO.md`. Run the dry run. | Before the apply. After it, check health. |
