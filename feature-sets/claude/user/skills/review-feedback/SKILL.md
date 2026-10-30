---
name: review-feedback
description: Pull the review comments of a pull request into one file, agree with the user on the changes, track them in a numbered TODO.md, and draft a reply under each comment. Publish the replies only when the user says so. Use when the user asks to fetch, work through, answer, or address the review comments or the change requests of a PR.
---

# Review feedback

Work through the review of one pull request in three files:

- `REVIEW.md` holds every comment and, below it, the draft reply.
- `TODO.md` holds the agreed tasks.
- The code holds the fixes.

Both files go in `_local/<branch>/`, as the "Local files" rules of
`~/.claude/rules/workflow.md` say.

## 1. Find the pull request

If the user names no PR, list the open PRs of the user with
`gh pr list --author @me`, and pick the PR that matches the request.

Check out the head branch of the PR.

If the local branch differs from the remote branch, show the difference and
ask before you reset it. The review anchors its lines to the remote commits.

## 2. Pull the comments

Run the script from the repository root:

```bash
python3 -I <skill folder>/scripts/review.py pull <owner/repo/pr>
```

It writes `_local/<branch>/REVIEW.md` in the layout of step 3. The `pull`
command also merges: it keeps the R numbers, the topics, and each reply
that is not sent yet. Run it again after the reviewer answers.

The script reads Reviewable only. Also read the GitHub inline comments with
`gh api --paginate repos/<owner>/<repo>/pulls/<n>/comments`. Skip the
comments that Reviewable mirrors. Add each other comment to `REVIEW.md` by
hand.

If the CLI fails, use the Reviewable MCP tools instead, and read
`reviewable://skills/respond-to-review-feedback` first.

## 3. Write REVIEW.md

Give each discussion one numbered section, in file order. Put the
discussions without a file first.

````markdown
<!-- markdownlint-disable MD013 MD035 -->

# Review of PR #31791

[#31791] · reviewers: bunert

| #    | Where          | Topic                  | Reply |
| ---- | -------------- | ---------------------- | ----- |
| [R1] | general        | PR description wording | +     |
| [R2] | service.rs:222 | spoofed `for`/`by`     |       |

-------------------------------------------------------------------

## R2. service.rs:222: spoofed `for`/`by`

[R2 thread] · [R2 code at review] · [R2 local file]

### bunert [blocking]

```rust
let (source, destination) = match ForwardedHeader::from_headers(req.headers()) {
```

> Hmm now we have the problem that a client can open a CONNECT tunnel and simply set the for/by
> to whatever they want.

### Reply [discussing]

`OPEN`

<!-- Links -->

[#31791]: <review url>
[R2]: #r2-servicers222-spoofed-forby
[R2 thread]: <discussion url>
[R2 code at review]: <github blob url at the revision sha>#L222
[R2 local file]: <path relative to REVIEW.md>/src/service.rs
````

The script writes this layout. Edit only these parts:

- The topic in each heading. A new thread gets the first words of its
  first comment. Shorten it, then run `pull` again, so the table links
  follow the new heading.
- The reply block: its text and its disposition.

The script sets each reply block that has no text:

- `OPEN`: the last comment comes from someone else, so the thread needs a
  reply.
- `NO REPLY`: the last comment is ours.

If a thread has a written reply, the table shows a `+` in its `Reply`
column.

## 4. Agree on the changes

Go through the threads with the user before you change code. For each
thread, propose one of these:

- Change the code. Say what changes.
- Push back. Give the reason.
- Ask the reviewer a question.
- Only acknowledge, for example for a bot comment.

Give a recommendation for each thread. Wait for the decisions of the user.

## 5. Write TODO.md

After the user agrees, write `TODO.md`:

```markdown
# TODO: review of PR #31791

1. [ ] Small fixes: WAP wording, misplaced doc comment, tuple type (R3, R9, R10)
2. [ ] Reject more than one `Forwarded` element (R6)
3. [ ] Add the parser tests that the review asks for (R5, R7)
4. [ ] Update the PR description
5. [ ] Publish the replies
```

Rules:

- Number each task. Give it a tickbox. Name the `R` numbers it answers.
- Group the small changes that need no discussion into one task. Put that
  task first. A small change is, for example, a comment fix, a rename, or a
  type that replaces a tuple.
- Give each larger change its own task.
- One task can answer several threads. One thread can need several tasks.
- Put the PR description update and the publication of the replies last.
- Write the PR description update with the `pr-description` skill. If the
  project rules hold a format for PR descriptions, follow that format
  instead.
- Never renumber a task. If a task drops, strike it through.

## 6. Work the tasks

Follow the "Work in steps" rules of `~/.claude/rules/workflow.md` for
each task.

After the commit of a task:

1. Tick the task in `TODO.md`.
2. Write the draft reply in `REVIEW.md` under each thread that the task
   answers. Set the disposition that you propose.
3. Run `pull` again, so the table shows the `+` for the new reply.

Keep each reply short:

- If the ask was small and the fix does what it asked, write `Done.`
- If the change was large, or differs from the ask, say what changed in
  one or two sentences.
- Do not name the commit.

Write each reply as plain technical text, by `~/.claude/rules/writing.md`.
The reply comes from the agent identity, so do not write it in the user's
voice.

If the user edits a reply in `REVIEW.md`, keep the edit. Read the file
again before you publish.

## 7. Publish

Publish only when the user tells you to. A finished task list is not an
instruction to publish.

1. Push the fixes first. The agent identity cannot use publish-on-push.
2. Run `python3 -I <skill folder>/scripts/review.py post <owner/repo/pr>`.
   It posts each written reply of `REVIEW.md` as a draft, and skips each
   reply that went out already. Then it compares the drafts with the file.
3. If the script reports a problem, fix it, and run `post` again.
4. Publish with `review_publish`, or with
   `reviewable review publish --pr=<owner/repo/pr>`.

The Reviewable MCP posts as an agent identity, not as the user. The user
cannot see the drafts of the agent in Reviewable. `REVIEW.md` is the only
place where the user reads the drafts.

For a GitHub comment, show the reply and the `gh` command first. Run it
only after the user says so.
