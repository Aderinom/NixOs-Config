---
name: issue-drafts
description: Plan GitHub issues as markdown drafts in a folder tree, with sub-issues, labels, board fields, and blockers, then create or change them with the gh CLI after approval. Also exports existing issues to drafts, so that the user can reorganize them. Use when the user asks to create, plan, break down, move, restructure, or refine issues, tickets, or sub-issues.
---

# Issue drafts

Write each issue as a markdown file first. The user reads and edits the
drafts in a code editor.

Change GitHub only after the user approves.

To reorganize existing issues, export them first (step 6). The exported
tree is a set of drafts like any other.

## 1. Find the context

- Find the repository. If it is not clear, ask.
- Find the parent issue. If the user names none, ask whether there is one.
- Read the parent: `gh issue view <n> --repo <owner/repo> --json title,body,labels,milestone`.
- Read its sub-issues: `gh api repos/<owner/repo>/issues/<n>/sub_issues --jq '.[] | "\(.number) \(.title)"'`.
  Do not draft an issue that already exists.
- Read the conventions of the repository: the title format in the project
  rules, and the title of the parent. Follow the same format.
- Number the titles only if the issues of one level have a real order,
  for example milestones where each one builds on the one before. The
  number goes right after the component prefix, for example
  `api: 01 add rate limits`. A sub-issue gets the number of its parent as
  a prefix, for example `api: 02.01 count requests per key`.
- Issues that can run in parallel get no number. Give either every issue
  of one level a number or none.
- List the labels: `gh label list --repo <owner/repo> --limit 500`. Use only
  labels that exist. Take the team and component labels of the parent.
- Find the board of the parent: `gh issue view <n> --repo <owner/repo> --json projectItems`.
  A board needs the `project` scope. If `gh auth status` does not list it,
  ask the user to run `gh auth refresh -s project`.

## 2. Split the work

- Give each issue a reasonable amount of work. Do not create tiny issues.
  Put small tasks that belong together into one issue.
- Split unrelated work, even if each part is small. A bug fix in the
  networking code and a CI pipeline are two issues.
- Nest freely. An issue can have sub-issues, and a sub-issue can have
  sub-issues of its own. Do not repeat a task in more than one issue.
- If work is already complete but not tracked, keep it in the issue that it
  belongs to, as a checked item.

## 3. Write the drafts

Put the drafts in `_local/issues/`, as the "Local files" rules of
`~/.claude/rules/workflow.md` say. If the user names another folder, use
that one.

```text
issues/
  123-<parent-slug>.sub/         sub-issues of parent issue #123
    01-<slug>.md
    02-<slug>.md
    02-<slug>.sub/               sub-issues of 02
      01-<slug>.md
```

- The file name is the title in lowercase, without the component prefix
  and without its number, with words joined by `-`. Keep it under 60
  characters.
- A two-digit prefix keeps the order of the files. If the title has a
  number, the prefix is the last part of it.
- The sub-issues of an issue go into a folder with the name of its file and
  the postfix `.sub`. For a parent that exists already, the folder name
  starts with its number.

Each file has a front matter and a body:

```markdown
---
title: "<title in the format of the repository>"
labels: [<label>, <label>]
parent: "#123"
status: Todo
priority: medium
assignees: [@me]
blocked_by: ["#120", "../01-<slug>.md"]
issue:
---

## Goal

One or two sentences.

## Scope

- [x] Work that is complete.
- [ ] Work that is open.

## Definition of done

- [ ] A condition that a reviewer can check.
```

- `parent` is `#<number>` for an issue that exists, or the relative path of
  the parent draft, for example `../02-<slug>.md`.
- `status` is the Status on the board. A new issue gets `Backlog`, `Todo`,
  or `Refine`.
- If the choice of Status is not clear, ask. The board has no default, so
  an issue without a Status gets lost.
- If the parent is on no board, `status` stays empty.
- `priority` is the Priority on the board, for example `high`, `medium`, or
  `low`.
- If the user gives no priority, leave out the `priority` key.
- For an existing issue, a missing key leaves that part of the issue as it
  is. This holds for `labels`, `status`, `priority`, `assignees`,
  `blocked_by`, and `state`.
- For an existing issue, an empty value clears that part, for example
  `labels: []` or `priority:`.
- `assignees` takes GitHub logins, and `@me` is the user of `gh`.
- If the user asks to take the issues, set `assignees: [@me]`.
- `blocked_by` lists the issues that block this one: `#<n>`,
  `<owner>/<repo>#<n>`, or the path of a draft. To say "A blocks B", put A
  into `blocked_by` of B.
- Write each list on one line, as in `[a, "b, c"]`. Quote an item that holds
  a comma or a bracket.
- `state: closed` closes the issue, and `state: open` reopens it.
- Board workflows can change an issue after `apply`. For example, the
  default workflows of a new board close an issue at `Done`.
- If a board closes issues at `Done`, give a closed issue the Status `Done`.
  Otherwise the board and the drafts disagree.
- `issue` stays empty until the issue exists. `updated` is the time of the
  last change that the drafts know.
- The script writes `issue` and `updated`.
- In the body, `#ref:<path>` names another draft, for example
  `#ref:../02-<slug>.md`. GitHub shows the issue number in its place.
- Write the scope as requirements. A checked item says what the issue needs,
  not what somebody did.
- Use a checkbox only for a task. Write facts, findings, and context as
  plain bullets, without `[ ]` or `[x]`.
- If an item has a choice between options, put each option in a sub-bullet
  without a checkbox. Label the options `a.`, `b.`, `c.`.
- If an item holds several facts, write a short lead line and put each fact
  in a sub-bullet. Indent sub-bullets by 4 spaces.
- Mark a sub-bullet that gives a reason or a consequence with `- → `.
  Facts and options keep a plain bullet.
- If a top-level item has sub-bullets or a code block, put a blank line
  after it.
- Keep top-level items without sub-bullets or a code block on consecutive
  lines.
- Write a definition of done for every issue. Each item is a condition that a
  reviewer can check, for example a behavior, a test that passes, or a
  document that exists. Do not repeat the scope items. If the work needs
  them, add the tests, the docs, and the changelog entry.
- Write in Simplified Technical English. Write each paragraph on one line.
- Add no attribution, no "Generated with" line, and no signature.

## 4. Check and get approval

`scripts/issues.py` in this skill folder does the mechanical part. It needs
`python3` and `gh`.

Pass the folder with the drafts of the first level. If its name starts with
an issue number, as in `123-<slug>.sub`, that issue is the parent of the
first level.

```bash
python3 <skill folder>/scripts/issues.py check <folder> --repo <owner/repo>
```

`check` reads the labels and the existing sub-issues on GitHub, and writes
nothing. It checks the front matter, the labels, the board fields, the
numbers in the titles and the file names, the parents, and the references.

`check` also refuses these drafts:

- Two drafts with the same title or the same issue.
- An issue URL of another repository than `--repo`.
- An existing issue with an empty body, because `apply` would erase the
  body on GitHub.
- A new draft without the three sections of the body.

The board is the board of the parent issue.

If the parent is on no board or on several, pass
`--project <owner>/<number>` to every command.

If `check` finds problems, fix the drafts and run it again. If it passes, it
prints the tree.

Then list the changes:

```bash
python3 <skill folder>/scripts/issues.py plan <folder> --repo <owner/repo>
```

`plan` compares the drafts with GitHub and writes nothing. It lists each
change that `apply` makes: create, title, body, labels, assignees, move,
Status, Priority, block, unblock, reopen, and close.

A move or a block that waits for a new draft shows `new <tree number>` in
place of the issue number.

`plan` also lists each conflict: an issue that changed on GitHub after the
drafts recorded its `updated` time.

Show the tree and the plan to the user and wait for approval. The user can
edit the files first.

Run `plan` again before you apply anything.

## 5. Apply the changes

```bash
python3 <skill folder>/scripts/issues.py apply <folder> --repo <owner/repo>
```

`apply` runs `check` and `plan` first.

If `plan` finds a conflict, `apply` stops before it writes anything. Then
export the issues again, and redo the changes.

`apply` keeps this order:

1. It creates the new issues, each parent before its sub-issues.
2. It reopens issues and removes blockers.
3. It changes titles, bodies, labels, and assignees.
4. It moves issues to their new parents.
5. It sets the board fields and adds blockers.
6. It closes issues, each sub-issue before its parent.

After each change, `apply` writes `issue` and `updated` into the drafts of
the issues that the change touched. A second run then resumes a run that
stopped, without a false conflict.

At the end, `apply` compares again. If a board workflow or a person changed
an issue during the run, `apply` lists the difference, and the next `plan`
reports a conflict.

`apply` never deletes an issue. A deleted draft only stops the management of
that issue.

`apply` changes an issue without a draft only through a draft:

- A move takes the issue from its old parent.
- A block adds the issue to the "blocking" list of the blocker.
- A new draft of the first level becomes a sub-issue of the top parent.

If an issue has more than 100 labels, assignees, blockers, sub-issues, or
boards, the script stops, because it cannot read the list in full.

Report the tree and the changes to the user. Keep the drafts until the user
says that they are done.

## 6. Export existing issues

```bash
python3 <skill folder>/scripts/issues.py export <n> <out folder> --repo <owner/repo>
```

`export` writes the open sub-issues of issue `<n>` as drafts into
`<out folder>/<n>-<slug>.sub/`, with all levels below them. It writes every
key, including `state` and `updated`.

Closed issues stay out of the export.

To reorganize, edit the exported tree:

- Move a draft into another `.sub` folder, and fix its `parent`, to move the
  issue.
- Edit the keys and the body to change the issue.
- Set `state: closed` to close the issue.
- Add a new draft for a new issue.

Then continue with step 4.

## Tests

`scripts/tests/sandbox.py` runs every command against a sandbox repository
and board, and closes its issues at the end. Its header lists what the
board needs.

`scripts/tests/offline.py` tests the parts that need no network.

Run both tests after each change to the script:

```bash
python3 <skill folder>/scripts/tests/offline.py
python3 <skill folder>/scripts/tests/sandbox.py --repo <owner/repo> --project <owner>/<number>
```
