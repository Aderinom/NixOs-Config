---
name: review
description: Review a code change of the user. Fix the findings that only follow the written rules. Put the findings that need a decision as comment threads on the code. Use when the user asks to review their own diff, branch, commit, PR, or files, and after each implementation step of a TODO.md. For a PR of someone else, use peer-review.
---

# Review

Find what is wrong with a change. Fix the findings that only follow the
written rules.

Ask the user about the rest.

## Target

Load the `diff-target` skill. It finds the change and its base.

## Run in an agent

Run the review in a new agent of type `general-purpose`, not in the main
session. Do not set `isolation`: the agent works in the review worktree.

If you are that agent, skip this section.

### The review worktree

The review worktree sits at `.claude/worktrees/review` in the repository.
It keeps one path across reviews, so the build cache of its crates stays
warm and a review rebuilds only the crates that the patch touches.

1. If the worktree does not exist, create it detached:
   `git worktree add --detach .claude/worktrees/review`.
2. If `.claude/worktrees/review/.review-lock` exists, another review uses
   the worktree. Use `.claude/worktrees/review-2` in the same way.
3. Create the lock file. Delete it when the agent returns.

### The agent

- Tell the agent the path of the review worktree. It runs every command
  there.
- Tell it to reset the worktree first: `git checkout --detach --force
  <hash of HEAD>`, then `git clean -fd`.
- If the target has uncommitted changes, write them to
  `_local/<branch>/review.patch` with `git diff --binary HEAD`. Tell the
  agent to apply the patch after the reset.
- Give the agent the base, the target, the patch, and the path of this
  skill. Tell it to follow the skill.
- Do not give it your summary of the change or your guess where the bugs
  are.
- Tell it which checks already pass in the main checkout, such as clippy
  and the tests. It builds only to reproduce a suspected bug.

When the agent returns, follow "Apply and report". Do not add findings of
your own.

## What to look for

Check in this order. Stop a pass early if it finds nothing.

1. Correctness. Wrong logic, off-by-one, unhandled error, missed edge case,
   race, resource leak, broken contract with a caller.
2. Security. Untrusted input, secrets in code or logs, unsafe defaults.
3. Tests. A new branch or a bug fix without a test that covers it.
4. Structure. Placement and names against the `code-structure` skill. Load
   it if the change adds, moves, or renames a unit.
5. Code layout, comments, and docs against
   `~/.claude/rules/code-layout.md` and
   `~/.claude/rules/writing.md`.
6. Simplification. Dead code, duplicate logic, an existing helper that the
   change does not use.

Follow the project rules where they differ from the global rules.

If the change is a pull request of someone else, load `peer-review`
instead.

## Kinds

Give each finding one of two kinds.

- `rule`: the fix only follows `code-layout.md` or `writing.md`, for
  example a thought comment, a binding before a call, a nested helper, the
  order of items, or the wording of a comment or a doc. The fix changes no
  behavior and no public API.

  A fix in test code that keeps what each test checks, and only makes its
  failures clearer or its form shorter, is a `rule` finding too.
- `decision`: everything else. Bugs, risks, missing tests, placement and
  names by `code-structure`, a change to a public API, and a change of
  behavior.

If you are not sure which kind a finding is, it is a `decision`.

## Severity

Give each `decision` finding a severity.

- `bug`: a failing test reproduces it, see "Reproduce".
- `risk`: a problem that you cannot reproduce here, for example because it
  needs root, an outside service, or a certain timing, or because it
  depends on intent. Say why you cannot reproduce it.
- `test`: a branch or a fix without a test.
- `structure`: placement, names, or public API.
- `nit`: a small change that is not a `rule` finding.

## Reproduce

For each suspected bug, write a test in the worktree that shows it. Run the
test.

- If the test fails, the finding is a `bug`. Return the test code with the
  finding, so the fix can keep it as the regression test.
- If you cannot write a test that fails, the finding is a `risk`. Say what
  stopped you.

Do not commit in the worktree.

## Verify

Before you return a finding, prove it from the code:

- Name the input or state that triggers it.
- Check that no caller, guard, or type already prevents it.
- If you cannot prove it, drop it, or make it a `risk` and say what is
  not proven.

Do not report style that a formatter or linter in the project already
checks.

## Output of the agent

One list, worst first. Each item:

```
<kind> <severity> <file>:<line> <one-sentence defect>
  Trigger: <input or state that causes it>
  Fix: <the concrete change>
  Test: <the test code that reproduces it, for a bug>
```

A `rule` finding has no severity and no test. Give file paths relative to
the repository root, and line numbers in the reviewed code.

If nothing survives Verify, say so in one sentence.

## Apply and report

Do this in the main session, after the agent returns.

1. Fix every `rule` finding in place, without asking first. Run the
   formatter and the tests of the touched packages.
2. Give each `decision` finding a key: F1, F2, and so on, worst first. If
   the review of the branch already has findings, continue its numbering.
3. Open a thread for each `decision` finding with the `code-threads`
   skill, in the review `<branch>-review`. See "Threads".
4. Report in chat:
   - the name of the review, so the user finds the threads;
   - one short block with the applied `rule` fixes, one line each;
   - a table of the `decision` findings: key, severity, file link, and
     the defect in a few words.

Then stop, and wait for the user.

## Threads

Put each finding on the lines that it names. Write the body like this:

```markdown
**F1 (bug):** <one-sentence defect>

Trigger: <input or state that causes it>

Fix: <the concrete change>
```

For a `bug`, add the test of the agent in a code block.

## The answer

The user answers in the threads, or in chat by key. Run `list` of the
`code-threads` script before you act.

- A reply says what to do. If the reply is not clear, ask in the thread.
- A resolve without a reply means: ignore the finding.
- A finding without a reply is still open.

If a chat answer and a thread disagree, ask the user.

## After the answer

- Apply what the user decides. For a `bug`, keep the test of the agent as
  the regression test.
- Keep each key. A fixed or ignored finding keeps its key, so the other
  keys stay the same.
- After a fix, reply in the thread with one line that says what changed.
  Then resolve the thread.
- Delete `review.patch` when the review ends.
