---
name: issue-drafts
description: Plan GitHub issues as markdown drafts in a folder tree, with sub-issues, labels, and a parent issue, then create them with the gh CLI after approval. Use when the user asks to create, plan, or break down issues, tickets, or sub-issues.
---

# Issue drafts

Write each issue as a markdown file first. The user reads and edits the
drafts in a code editor. Create the issues only after the user approves.

## 1. Find the context

- Find the repository. If it is not clear, ask.
- Find the parent issue. If the user names none, ask whether there is one.
- Read the parent: `gh issue view <n> --repo <owner/repo> --json title,body,labels,milestone`.
- Read its sub-issues: `gh api repos/<owner/repo>/issues/<n>/sub_issues --jq '.[] | "\(.number) \(.title)"'`.
  Do not draft an issue that already exists.
- Read the conventions of the repository: the title format in the project
  rules, and the title of the parent. Follow the same format.
- Number the titles in their order, right after the component prefix, for
  example `api: 01 add rate limits`. A sub-issue gets the number of its
  parent as a prefix, for example `api: 02.01 count requests per key`.
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

Put the drafts in a folder. If the user names none, ask, and offer
`issues/` in the working directory.

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
- A two-digit prefix keeps the order of the issues. It is the last part of
  the number in the title.
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
  or `Refine`. If the choice is not clear, ask. The board has no default, so
  an issue without a Status gets lost. If the parent is on no board,
  `status` stays empty.
- `issue` stays empty until the issue exists.
- Write the scope as requirements. A checked item says what the issue needs,
  not what somebody did.
- Write a definition of done for every issue. Each item is a condition that a
  reviewer can check, for example a behavior, a test that passes, or a
  document that exists. Do not repeat the scope items. If the work needs
  them, add the tests, the docs, and the changelog entry.
- Write in Simplified Technical English. Write each paragraph on one line.
- Add no attribution, no "Generated with" line, and no signature.

## 4. Check and get approval

`scripts/issues.py` in this skill folder does the mechanical part. It needs
`python3` and `gh`. Pass the folder with the drafts of the first level. If
its name starts with an issue number, as in `123-<slug>.sub`, that issue is
the parent of the first level.

```bash
python3 <skill folder>/scripts/issues.py check <folder> --repo <owner/repo>
```

`check` reads the labels and the existing sub-issues on GitHub, and writes
nothing. It checks the front matter, the labels, the Status against the
options of the board, the numbers in the titles and the file names, the
parents, the sections of the body, and duplicate titles. The board is the
board of the parent issue. If the parent is on no board or on several,
pass `--project <owner>/<number>`. If it finds problems, fix the drafts and run it again. If it passes,
it prints the tree.

Show the tree to the user and wait for approval. The user can edit the
files first. Run `check` again before you create anything.

## 5. Create the issues

```bash
python3 <skill folder>/scripts/issues.py create <folder> --repo <owner/repo>
```

`create` runs `check` first. It creates each parent before its sub-issues,
attaches each issue to its parent, sets its Status on the board, and writes
the URL into `issue`. It skips
a draft whose `issue` is set, so a second run resumes a run that stopped.
When all issues exist, it prints the tree with the issue numbers and deletes
the drafts. `--keep` keeps them.

Report the tree to the user.
