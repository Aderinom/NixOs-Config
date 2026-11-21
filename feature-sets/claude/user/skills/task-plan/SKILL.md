---
name: task-plan
description: Write and keep the TODO.md of a task that spans several steps or sessions, with the current state, the steps and their effects, the decisions and the options that lost, the checked facts, and notes. Then let a fresh agent review the plan before step 1. Use when you plan such a task, when you resume one, or when you change its TODO.md.
---

# Task plan

The `TODO.md` of a task is the only state that survives a new session and a compaction in full. Write it for the next session, which knows nothing of the chat.

The file sits in `_local/<branch>/TODO.md`. `workflow.md` sets how you run the steps.

## Template

```markdown
# <short name> (#<issue>)

Goal: <the goal in one or two sentences>

<the base branch or PR, if the branch stacks on one>

Now: <step, state, and what blocks it>

## Steps

1. [ ] <unit>: <what the step does>

   Effect: <what changes in observable behavior>

   Result: <commit>

## Decisions

- Q1: <question>. Decided: <choice>, because <reason>.

  Turned down: <option>, because <reason>.

## Facts

- <checked fact> (`<file>:<line>`)
- Unchecked: <assumption>. Step <n> depends on it.

Test command: `<command>`

## Notes

- PR description: <point for the PR description>

## Later topics

- <a topic outside this task>
```

Leave out a section that has no content.

## Sections

### Now

One line holds the step, its state in `workflow.md`, and what blocks it. Example: "Step 2 done in `abc123`. Waiting for your answers on threads 3 and 5."

Update the line before each stop. If the line is stale, the next session does the wrong work.

### Steps

Each step names the unit that it changes and what it does.

`Effect:` holds the change in observable behavior, in one line. Write it when you plan, not after the code.

If a step has no observable effect, write that and say what the next step adds.

The `Effect:` lines test the cut of the plan:

- If a step needs "and" several times, split it.
- If the effects of all steps do not reach the goal, a step is missing.

Skip `Effect:` for a mechanical step, such as a move.

`Effect:` is not a test list. The `test-writing` skill agrees on the cases with the user.

If the user comments before the cleanup and the review of a step are done, add the comment under the step as `Feedback:`.

When you apply the feedback, delete the line. The commit holds the change.

When a step ends, tick it and add `Result:` with the commit.

### Decisions

Each decision keeps its key, as `workflow.md` sets. It holds the question, the choice, and the reason.

Add a `Turned down:` line for each option that lost, with its reason. A letter such as "(b)" alone is useless in a new session, because the options are gone.

If the change has an OpenSpec `design.md`, the decisions go there. `TODO.md` then points at it.

### Facts

A fact is something that you checked in the code or in a run, with its `file:line`. An assumption gets the mark `Unchecked:` and names the steps that depend on it.

Put only facts that a grep does not show in a minute.

If you check an assumption, turn it into a fact or delete it.

Write the test command once, here.

### Notes

Notes hold points for later text, such as the PR description or a reply to a reviewer.

### Later topics

Later topics hold what you found outside the task, such as a bug in another unit. They do not block a step.

## Plan review

Before step 1, start a fresh agent to review the plan. Give it the path of `TODO.md` and the code, not the chat, so that our reasoning does not anchor it.

Ask the agent to find:

- assumptions that the plan does not mark as `Unchecked:`.
- steps that are missing, or a step that is too big.
- `Effect:` lines that do not reach the goal together.
- decisions without a reason or without the options that lost.

Show the findings to the user. Change the plan only after the user agrees.

## Upkeep

- Write each fact in one section only. Point at it from the other sections.
- Delete what is no longer true. A wrong line is worse than no line, because the next session trusts the file.
- Keep the file short. The next session reads all of it.
