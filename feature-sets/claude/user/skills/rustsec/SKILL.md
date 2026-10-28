---
name: rustsec
description: Work through the RUSTSEC advisories of a Rust repository. Collect the open RUSTSEC issues and the cargo audit findings of every Cargo.lock. Mark the solved ones, fix the easy ones in one commit, then fix the hard ones one at a time. Use when the user asks to go through, triage, or fix RUSTSEC issues or cargo audit findings.
---

# RUSTSEC advisories

`scripts/rustsec.py` in this skill folder does the mechanical part. It needs
`python3`, `git`, `gh`, and `cargo-audit` or `nix`. Read its header for the
details.

## The document

The work can span several sessions, so it keeps its
state in `RUSTSEC.local.md` at the repository root. The file never goes into
a commit.

It has these sections, in this order:

- The header and `## Advisories`, from the script. The `Class` column holds
  the state of each row: `todo`, `solved`, `easy`, `hard`, `fixed`, or
  `skip`.
- `## Titles`, from the script.
- `## Scope`: the workspaces that the user left out, with the reason.
- `## Issues to close`: the solved issues, with the state of each.
- `## Hard advisories`: one entry for each hard fix, with a checkbox.
- `## Commits`: each commit, with the `Fixes #<n>` lines for its issues.

If you change a cell, align the table again.

## 0. Start a branch

1. If `git status` shows changes, ask the user what to do with them.
2. Fetch the default branch, and create the branch from its tip:
   `git switch -c rustsec-<yyyy-mm-dd> <remote>/<default branch>`. If the
   project rules set a branch name format, use it.

## 1. Collect the advisories

1. Find the repository that holds the RUSTSEC issues. It is the repository
   where the audit workflow runs, often `upstream` and not the fork. If it
   is not clear, ask.
2. Run the script from the repository root, and write its output to a file
   in your scratchpad:

   ```bash
   python3 -I <skill folder>/scripts/rustsec.py --repo <owner/repo> > <scratchpad>/rustsec.md
   ```

3. If `RUSTSEC.local.md` exists, it holds the decisions of an earlier
   session. Merge the new table into it, and keep the `Class` values and the
   other sections. Else copy the output to `RUSTSEC.local.md`.
4. If `git check-ignore -q RUSTSEC.local.md` fails, add the line
   `RUSTSEC.local.md` to the file that `git rev-parse --git-path info/exclude`
   prints.
5. If the header lists audit errors, tell the user.
6. If some workspaces look vendored (for example under `third_party/`), or
   only serve fuzzing, ask the user which ones are in scope. Set the rows
   of the other ones to `skip`, and write the reason under `## Scope`.

## 2. Find the solved issues

The script marks a row `solved` if an open issue names a crate version that
no lockfile holds.

1. If the same advisory has a `todo` row, the issue stays open. Else list
   the issue under `## Issues to close`.
2. Show the list to the user. Close the issues only after the user approves:

   ```bash
   gh issue close <n> --repo <owner/repo> --reason completed --comment "No Cargo.lock in the repository holds <crate> <version> any more."
   ```

3. Mark each closed issue in the document.

## 3. Sort the easy from the hard

Look at each `todo` row in its workspace folder.

- A row is `easy` if a patched version exists and `cargo update` reaches it
  with no change to a `Cargo.toml`. Check it with
  `cargo update --dry-run -p <crate>@<version>`. The new version must be in
  the `Patched` range.
- Every other row is `hard`, for example:
  - The fix needs a new major version, or a new minor version of a `0.x`
    crate.
  - No patched version exists, as for an unmaintained crate.
  - A parent crate pins the old version.
- `cargo tree -i <crate>@<version> --target all` shows which crates pull in
  the version.

Set the `Class` of each row. For each hard fix, add an entry under
`## Hard advisories`. If several rows share one fix, as with many advisories
on one crate, they share one entry. The entry holds the advisory IDs, the
workspaces, the crates that pull in the version, and the issues.

## 4. Update the easy ones

1. In each workspace with `easy` rows, run
   `cargo update -p <crate>@<version>` once for each row. Never run a bare
   `cargo update`, because it bumps every crate.
2. If a workspace uses the crates of another workspace by path, each
   workspace still has its own lockfile. Update each lockfile.
3. Build each changed workspace with `cargo check --locked --all-targets --all-features`.
   If `.cargo/config.toml` of the workspace has a CI alias, use the alias.
4. If Bazel reads a Cargo.lock, as `from_cargo`, `crates_repository`, or
   `cargo_lockfile` in `MODULE.bazel` or `WORKSPACE` shows, look for labels
   with the old version in the `BUILD` files, for example
   `<crate>-<old version>`. Update them. Then build the Bazel targets that
   use the crate, and keep the changes to `MODULE.bazel.lock`.
5. Run the script again into the scratchpad. Set each row that is gone to
   `fixed`. If an `easy` row is still there, set it to `hard`, and add its
   entry.

## 5. Commit the updates

1. Read the project rules for the commit title format and for changelog
   entries.
2. Stage only the files of this update by name: the lockfiles, and the
   Bazel and `BUILD` files that you changed. Do not use `git add -A`.
3. Commit, and write the commit and its `Fixes #<n>` lines under
   `## Commits`.

## 6. Fix the hard ones

Run each entry under `## Hard advisories` as one step of the "Work in steps"
rule. Start with vulnerabilities, then unsound crates, then unmaintained
crates. Inside one kind, start with the entry that has the most workspaces.

For each entry:

1. Read the advisory at `https://rustsec.org/advisories/<id>.html`. Find out
   if the code calls the affected API. Search for the names that the
   advisory gives.
2. Give the user the options, with a recommendation. The user decides.
   - a. Raise the version requirement in `Cargo.toml`, and fix the code for
     the new API.
   - b. Update or replace the parent crate that pins the old version.
   - c. Replace an unmaintained crate. The advisory often names a successor.
   - d. Accept the advisory. Add its ID to `ignore` in the
     `.cargo/audit.toml` of the workspace, with a comment that gives the
     reason. Only the user makes this decision.
3. Do the fix, then build and run the script again, as in step 4.
4. Set the rows of the entry to `fixed`, check its box, and add the commit
   under `## Commits`.
