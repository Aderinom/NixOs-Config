---
name: commit-review
description: Walk a branch commit by commit for a review. Stop at each commit, collect the findings of the user from chat and from REVIEW comments in the code, fix each finding at once or log it, and fold the logged fixes into their commits at the end. Use when the user asks to review a branch commit by commit, to walk through the commits of a branch, or to fix things in older commits of a branch.
---

# Commit review

Walk the commits of a branch one at a time. At each commit, the user reviews
the diff and marks findings.

You fix each finding at once or log it. At the end, the logged fixes go into
the commits that they belong to.

A call of this skill is the request to run the git commands below. Never
push.

## 1. Set up

1. Find the branch and its base with the `diff-target` skill. If the user
   names a start commit, the review starts at the commit after it, so that
   commit is the base.
2. Make sure that `git status` shows no changes, apart from `_local/`. If it
   does, ask the user whether to commit or stash them.
3. Create the backup branch `<branch>-review-backup` at `HEAD`.

   If it exists, ask the user before you move it.
4. Create the log `_local/<branch>/commit-review.md`:

   ```markdown
   # Commit review: <branch>

   Base `<base>` · backup `<branch>-review-backup`
   ```

5. List the commits with `git log --reverse --format='%h %s' <base>..HEAD`.
   Show the list, so the user sees the scope.
6. Start the walk:

   ```bash
   GIT_SEQUENCE_EDITOR="sed -i 's/^pick /edit /'" git rebase -i --no-update-refs <base>
   ```

   The sequence editor sets each commit to `edit`, so no editor opens. Git
   applies the first commit and stops.

   The flag `--no-update-refs` keeps the backup branch at the old commits.
   Without it, a global `rebase.updateRefs` moves the backup branch along
   with the rebase.

## 2. At each commit

1. Show the position, for example `2/6`, the short hash, the title, and
   `git show --stat --format= HEAD`. Note the hash, because steps 6, 8, 11,
   and 12 need it.
2. Undo the commit, and keep its content staged:

   ```bash
   git reset --soft HEAD~1
   ```

   The Source Control view of the editor shows only changes against
   `HEAD`. So it now lists the commit under "Staged Changes".
3. Split the commit into mechanical files and files for a closer review:

   ```bash
   <skill folder>/scripts/split.sh
   ```

   The script keeps the mechanical files staged. It unstages each new file
   and each file with more than 30 changed tokens, so the editor lists them
   under "Changes". A rename changes about one token per line, so a
   mechanical file stays below the limit. Show the output of the script.
4. Add a section for the commit to the log:

   ```markdown
   ## 2/6 `9af1c12653` endhost/public: add Kani proofs for the sciparse parse path
   ```

5. Wait for the user. The user reads the staged and the unstaged changes in
   the editor, and marks findings in three ways:
   - in chat, with the file and the line;
   - as `REVIEW:` comments in the code, in the comment syntax of the file;
   - as a fix in the code, written by the user.
6. When the user says that the commit is done, list the edits of the review
   with `git diff <hash>`. The diff compares the working tree with the
   original commit, so it shows each edit of the stop, and nothing of the
   commit itself. Each `REVIEW:` line is a marker. Each other change is a
   fix of the user. Read the file around each edit.
7. Add each finding to the commit section of the log, in one line:

   ```markdown
   1. [ ] now · `read.rs:55` · Rename `BUF_LEN` to `MAX_LEN`.
   2. [ ] later · `write.rs:20` · Explain why the lane holds 16 bytes.
   3. [x] user · `slice.rs:30` · Fixed the doc of `get_debug_checked`.
   ```

   A fix of the user is done, so it needs no decision in step 8.

8. Ask the user for each finding whether to fix it now or later. Give a
   recommendation:
   - Recommend `now` for a small fix that no later commit touches. Check
     with `git log --format='%h %s' <hash>..<branch>-review-backup -- <file>`.
   - Recommend `later` if a later commit changes the same lines, so the fix
     cannot cause a rebase conflict.
9. Remove the markers from the code by an edit. Never restore a file to
   remove a marker, because the restore also drops the fixes of the user and
   the unstaged part of the commit.
10. Fix each `now` finding. Follow the rules for code and text, and run the
    build of the changed crate.
11. Show the edits of the stop, and wait for the approval of the user:
    - `git diff <hash>`, which holds the fixes of the user and your fixes;
    - the untracked files from `git status --short`, because the diff does
      not list them and step 12 stages them.

    After the approval, tick the findings in the log.

    If a fix touches a file that a later commit changes, warn the user,
    because `git rebase --continue` can then stop on a conflict.
12. Stage everything, and commit again with the message and the author of
    the original commit:

    ```bash
    git add -A
    git commit -C <hash>
    ```

13. Make sure that `git status` shows no changes, apart from `_local/`. Then
    run `git rebase --continue`.

If the rebase stops on a conflict, show the conflict. Resolve it with the
user, then continue.

The new commit of a stop gets a new hash, and so does each later commit.
So refer to a commit by its title, not by its hash.

## 3. Fold in the logged fixes

After the last commit, the rebase ends. Then:

1. Fix each open `later` finding. Show the diff, and wait for the approval
   of the user.
2. Commit each fix as a fixup of its commit. Find the commit by its title:

   ```bash
   git commit --fixup="$(git log --format=%h -n 1 -F --grep='<title>' <base>..HEAD)"
   ```

   Several fixes for one commit can share one fixup commit.
3. Fold the fixups into their commits:

   ```bash
   GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash --no-update-refs <base>
   ```

4. Tick the findings in the log.
5. Show the effect of the review with
   `git range-diff <base>..<branch>-review-backup <base>..HEAD`.

Keep the backup branch. Delete it only when the user says so.

## Abort

- To stop the walk and undo the changes of the current walk, run
  `git rebase --abort`.
- To return to the state before the review, reset the branch to
  `<branch>-review-backup`. Ask the user first, because the reset drops all
  fixes.
