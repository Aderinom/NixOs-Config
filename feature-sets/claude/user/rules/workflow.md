# Workflow

## New task types

If no skill or rule covers a task type, load `task-flow`.

## Start on a ticket

If I give you a GitHub issue to work on, first set its Status on the board to
`In Progress`, and assign it to me (`gh issue edit <n> --add-assignee @me`).

## Work in steps

If you write, resume, or change the `TODO.md` of a task, load `task-plan`.

If a task has a `TODO.md` with steps, run each step in this order:

1. Do the step. Load the skills the step needs, such as `code-structure`,
   and ask me where a decision is mine.
2. Stage the files with only mechanical changes, such as moves, imports,
   dependencies, and lock files. The editor then lists only the files for
   my review under "Changes".

   Do this before any check, because some checks read the file list from
   the index.

   The script `scripts/split.sh` of the `commit-review` skill sorts the
   staged files by size. Stage the rest of the mechanical files by hand.
3. Clean up the new code with `cleanup`.
4. Review the new code with `review`. It fixes the `rule` findings and
   puts the rest as threads on the code.
5. Stop, and wait for my review and my answers to the findings. Apply my
   feedback.
6. Write the tests with `test-writing`.
7. When I approve the step, commit. An approval is a clear OK of the
   step, such as "looks good" or "commit".

   A remark on another topic is not an approval.

   If you are not sure, ask.

   After the commit, delete the review threads of the step from
   `.review/`, and start the next step.

Do not start the tests before my review of step 5.

If I comment on the code before steps 3 and 4 are done, write my comment
in `TODO.md`.

Tell me that you noted it, and that you apply it after the review. Then
finish the cleanup and the review, and apply the comment in step 5.

## Open decisions

Give each open decision a key: Q1, Q2, and so on. Use the key in chat, in
`TODO.md`, and in the steps that wait for the decision.

If you answer or remove a decision, keep its key. The other keys then stay
the same.

## Local files

Keep each file that is not for the repository in `_local/` at the
repository root. It holds `TODO.md`, review files, notes, and drafts.

- Put the files of one branch in `_local/<branch>/`.
- Put the files of the whole repository directly in `_local/`, for
  example issue drafts.

Never commit `_local/`. The global git ignore holds it.

## Clean up

Delete each branch and worktree that you create for your own use when its
work ends, without asking. Examples are a backup branch and the worktree of
an agent.

The review worktrees of the `review` skill stay. That skill gives the reason.

## Edit files

- Change files with `Edit` or `Write`, so the text check sees the new text.
- Use a shell command only for a mechanical change across many lines, or for
  output that a tool writes.
