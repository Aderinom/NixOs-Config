---
name: peer-review
description: Review the pull request of a colleague together with the user. Map the change and its open discussions first. Collect the findings as code threads, so the user can rewrite them. Publish them to Reviewable after approval. Use when the user asks to review a PR of someone else.
---

# Peer review

Review the pull request of a colleague together with the user. The user owns
the review, so each published comment is in the words of the user.

The rules in `~/.claude/rules/` are private to the user. Do not hold the
code of the colleague to them.

## Files

All files go in `_local/<branch>/`, as the "Local files" rules of
`~/.claude/rules/workflow.md` say.

- `DISCUSSIONS.md` holds the discussions that already exist on the PR.
- `MAP.md` tells the user where to read and what to check.
- `REVIEW.md` holds the new comments, with the keys C1, C2, and so on.

## 1. Check out the PR

If the user names no PR, ask for it.

If the working tree has changes, ask before you switch. Then check out the
head branch with `gh pr checkout <n>`.

## 2. Pull the discussions

Run the `pull` command of the `review-feedback` script:

```bash
python3 -I ~/.claude/skills/review-feedback/scripts/review.py pull <owner/repo/pr> --file _local/<branch>/DISCUSSIONS.md --open-only
```

The script also puts each open discussion on its line of code, in the
review `<branch>-feedback` of the `code-threads` skill. Tell the user the
name of the review.

Skip the done discussions in all later steps. `DISCUSSIONS.md` lists
them under "Done".

## 3. Map the change

Write `MAP.md` before any finding. It tells the user where to read and
what to check.

Keep it under about 30 lines.

- The goal of the PR, in one sentence.
- The discussions where the user acts next, with the action.
- The files that carry the design, in reading order, at most about 5.
  Give each file one line on its role and one question to check.
- One line that names the files to skip.
- The flow, in at most about 6 lines.
- Each point where the PR description and the code disagree.

If "Last reviews" in `DISCUSSIONS.md` puts the user at an older commit
than the head, add a section "Since the last review" to `MAP.md`. Put
`git log --oneline <commit>..HEAD` and the changed files in it.

Steps 4 and 5 still cover the whole PR.

Start step 4 in the background, then tell the user that the map is ready.

If the user asks about the design, answer from the code in chat.

## 4. Find

Run the two passes below in parallel. Do not change the code.

### Team pass

If the repository has `.claude/commands/pr-review.md`, follow its steps 1
to 6 for the PR. Skip its output step, because the findings go to step 5.

If the repository has no such command, run the agent of the `review`
skill. Tell it that the change is not the user's own:

- Check the code layout, the comments, and the docs only against the
  project rules.
- Skip `~/.claude/rules/code-layout.md`. Use `writing.md` only for facts
  that are stale or wrong.
- Fix nothing in place, and report each `rule` finding as a `nit`.

### Design pass

Run one agent of type `general-purpose`. Give it the diff, `MAP.md`, and
these questions:

- Does each thing keep one name across the code, the docs, and the PR
  description?
- Do two code paths that do the same job follow the same rules?
- Does each name match what its unit does?
- Does each doc comment match the code that it describes?
- Does each new abstraction have a caller in production code?

The agent proves each finding from the code, and names the lines.

### Merge

Merge the findings of the two passes. Add each point where the PR
description and the code disagree, from `MAP.md`. If two findings name
the same defect, keep one.

If an open discussion in `DISCUSSIONS.md` already holds a finding, drop the
finding.

## 5. Collect at the code

Load the `code-threads` skill. Run `use <branch>-review`, and tell the user
the name of the review.

Open one thread for each finding, on the lines that it names. Start each
body with `🤖`. Then write the finding as a comment to the author: the
defect, the trigger, and the fix.

The user adds threads of their own to the same review:

- A resolved thread drops out of the review.
- A reply of the user to a thread says what to change.

Run `list --all` before you act on the threads.

## 6. Write REVIEW.md

When the user says that the threads are done, run `list --all`. Then write
`REVIEW.md` from the threads that are still open:

```bash
python3 -I <skill folder>/scripts/review_md.py build --pr <n> \
  --topic <thread>=<topic> ... --blocking <thread>,<thread>
```

The docstring of `scripts/review_md.py` holds the format of the file and
the rule for the text of each comment.

Give each open thread a topic of a few words. The script stops if a topic
is missing.

The state is the Reviewable disposition of the comment, `blocking` or
`discussing`:

- `blocking`: an important fix, for example a bug, a security risk, a
  wrong behavior, or a broken contract.
- `discussing`: a nit, a question, or a point that is not important.

List the threads that you propose as `blocking` in `--blocking`. All other
threads get `discussing`.

If a thread sits on a poor line, fix the line in the heading of its
comment after the build.

The user edits the comment text and the state in the file.

If the table and a `State:` line disagree, ask the user.

If the user asks, fix the typos. Change nothing else.

## 7. Publish

Publish only when the user says so.

1. Read `REVIEW.md` from the payloads:
   `python3 -I <skill folder>/scripts/review_md.py parse`. If it stops on
   a state that disagrees with the table, ask the user.
2. Run the `pull` of step 2 again. If a comment repeats a discussion, list
   it, and ask the user.
3. Read `reviewable://skills/choose-review-provider` and
   `reviewable://skills/review-code` of the `reviewable` MCP server.
4. Get the latest revision with `review_revisions_list`, and the file keys
   with `review_files_list`.
5. List the drafts of the user with `review_discussions_list` and the query
   `+draft`. If drafts exist, ask the user.
6. Create each comment of the `parse` output at the latest revision with
   `review_discussions_create`. Send its `body`, `path`, `line`, and
   `disposition` unchanged, also for `discussing`.
7. Publish with `review_publish`.
8. Check the state of the review on GitHub:
   `gh api repos/<owner>/<repo>/pulls/<n>/reviews --jq '.[-1].state'`.

The GitHub state follows from the dispositions:

| Comments                   | State               |
| -------------------------- | ------------------- |
| at least one `blocking`    | `CHANGES_REQUESTED` |
| only `discussing`          | `COMMENTED`         |

The `github_state` of the `parse` output holds the expected state.

If the GitHub state does not match it, tell the user.

Never send an approval or an LGTM unless the user asks for it.

The summary line of Reviewable can show `@<user>+LGTM` without an approval.
Use the GitHub state, not the summary line.

Never create a GitHub pending review. Reviewable does not publish while
one exists.
