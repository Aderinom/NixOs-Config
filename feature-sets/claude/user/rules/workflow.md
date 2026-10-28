# Workflow

## Start on a ticket

If I give you a GitHub issue to work on, first set its Status on the board to
`In Progress`, and assign it to me (`gh issue edit <n> --add-assignee @me`).

## Work in steps

If a task has a `TODO.md` with steps, run each step in this order:

1. Do the step. Load the skills the step needs, such as `code-structure`,
   and ask me where a decision is mine.
2. Run a layout and text review on the new code with `style-review`.
3. Stop, and wait for my review. Apply my feedback.
4. Write the tests with `test-writing`.
5. When I approve, commit, and start the next step.

Do not start the tests before my review of step 3.
