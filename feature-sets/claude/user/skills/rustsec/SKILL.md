---
name: rustsec
description: Work through the RUSTSEC advisories of a Rust repository. Collect the open RUSTSEC issues and the cargo audit findings of every Cargo.lock. Mark the solved ones, fix the easy ones in one commit, then fix the hard ones one at a time. Use when the user asks to go through, triage, or fix RUSTSEC issues or cargo audit findings.
---

# RUSTSEC advisories

The scripts in `scripts/` of this skill folder do the mechanical part. Each
script header holds the details.

- `rustsec.py` collects the advisories into a table. It needs `python3`,
  `git`, `gh`, and `cargo-audit` or `nix`.
- `validate.py` checks advisories against every lockfile, straight from the
  advisory database. It honors the `ignore` list of each workspace.
- `setclass.py` sets the `Class` of table rows, and aligns the table.

## The document

The work can span several sessions, so it keeps its state in
`_local/<branch>/RUSTSEC.md` at the repository root. The file never goes into
a commit.

It has these sections, in this order:

- The header and `## Advisories`, from the script. The `Class` column holds
  the state of each row: `todo`, `solved`, `easy`, `hard`, `fixed`, or
  `skip`.
- `## Titles`, from the script.
- `## Scope`: the workspaces that the user left out, with the reason.
- `## Issues to close`: the solved issues, with the state of each.
- `## GitHub updates`: the comments and closes that wait for the user.
- `## Hard advisories`: one entry for each hard fix, with a checkbox.
- `## Breaking and behavior changes`: each change that a user of the code
  sees, with its commit. The PR description takes them from here.
- `## Commits`: each commit, with the `Fixes #<n>` lines for its issues.

If you change a cell, run `setclass.py`, or align the table again by hand.

Write `Proposal:` in an entry until the user decides. Then change it to
`Decision:`.

## GitHub updates

A comment or a close on an issue goes out to other people, so the skill
collects them under `## GitHub updates`. Send the batch only after the user
releases it.

A comment on an issue that stays open has four parts:

1. What is affected: the crate version, our crates that use the first
   third-party crate of the chain directly, and the chain itself.
   `cargo tree -i <crate> --depth 1 --prefix none` lists the direct users.

   Write them as a list, one crate per line, under a line that names the
   third-party crate they use.
2. Why the issue stays open.
3. Why the advisory is not critical for this code, for example because the
   code never calls the affected API, or holds no secret for it.
4. What fixes it, for example a version bump or an upstream change.

Before you write the fourth part, search the upstream repository of each
crate in the chain for an open issue or PR about the fix. Link each one that
you find.

If you find none, say so in the comment.

If the upstream fix has an issue, also mark our issue as blocked by it. The
API takes the internal ID of the upstream issue, not its number:

```bash
gh api repos/<owner>/<repo>/issues/<upstream n> --jq .id
gh api -X POST repos/<owner/repo>/issues/<n>/dependencies/blocked_by -F issue_id=<id>
```

A PR cannot block an issue. If the upstream fix exists only as a PR, the
link in the comment is the only reference.

Write crate names, paths, and code identifiers in backticks, so that GitHub
renders them as code. Leave issue and PR links such as `owner/repo#12` plain.

An issue that a commit of the branch fixes gets a `Fixes #<n>` line in the
PR description, and no comment.

## Breaking and behavior changes

Check each fix for changes that a user of the code sees, before you commit
it. Write each one under `## Breaking and behavior changes`, with its commit.

A fix breaks a public API if a changed crate reaches it:

- A `pub use` re-exports the crate.
- A public type implements a trait of the crate, for example `ToSchema`.
- A public signature takes or returns a type of the crate.

This matters if the fix moves the crate to a new major version, or a `0.x`
crate to a new minor version. It also matters if the fix turns a feature off,
because a re-export then loses the items behind that feature.

The local build compiles only the code for the host platform. After a
major bump, search the code for `cfg(target_os = …)` and `cfg(windows)`
branches that use the changed crate, and check them against the new API.

A behavior change is a different result for a caller, a user, or an
operator. Examples are another log level, a dropped compression format, or
another file format. The upstream changelog of the crate often names them.

## Long checks

A background shell job stops after 10 minutes. Start a long check detached
(`nohup setsid`) with its log in your scratchpad. Then wait in the background
for a marker file that the check writes at its end.

Full builds of several workspaces fill the disk fast. Delete each log as soon
as you have read it.

## 0. Start a branch

1. If `git status` shows changes, ask the user what to do with them.
2. Fetch the default branch, and create the branch from its tip:
   `git switch -c rustsec-<yyyy-mm-dd> <remote>/<default branch>`. If the
   project rules set a branch name format, use it.

## 1. Collect the advisories

1. Find the repository that holds the RUSTSEC issues. It is the repository
   where the audit workflow runs, often `upstream` and not the fork. If it
   is not clear, ask.
2. Find the workspaces that CI audits, in the audit jobs under
   `.github/workflows`. The issues come only from those workspaces.
3. Run the script from the repository root, and write its output to a file
   in your scratchpad:

   ```bash
   python3 -I <skill folder>/scripts/rustsec.py --repo <owner/repo> > <scratchpad>/rustsec.md
   ```

4. If `_local/<branch>/RUSTSEC.md` exists, it holds the decisions of an
   earlier session. Merge the new table into it, and keep the `Class` values
   and the other sections.

   Else copy the output to `_local/<branch>/RUSTSEC.md`.
5. If the header lists audit errors, tell the user.
6. If some workspaces look vendored (for example under `third_party/`), or
   only serve fuzzing, ask the user which ones are in scope. Set the rows
   of the other ones to `skip`, and write the reason under `## Scope`.

## 2. Find the solved issues

The script marks a row `solved` if an open issue names a crate version that
no lockfile holds.

1. Check each solved advisory with `validate.py`. Pass each out-of-scope
   workspace with `--skip`. An advisory is solved only if no in-scope
   lockfile holds an `AFFECTED` version.
2. If the same advisory has a `todo` row, the issue stays open. Else list
   the issue under `## Issues to close`.
3. Add the close to `## GitHub updates`. When the user releases the batch,
   close each issue:

   ```bash
   gh issue close <n> --repo <owner/repo> --reason completed --comment "No Cargo.lock in the repository holds <crate> <version> any more."
   ```

4. Mark each closed issue in the document.

## 3. Sort the easy from the hard

Look at each `todo` row in its workspace folder.

- A row is `easy` if a patched version exists and `cargo update` reaches it
  with no change to a `Cargo.toml`. Check it with
  `cargo update --dry-run -p <crate>@<version>`. The new version must be in
  the `Patched` range.
- If that dry run does not fix the row, dry-run each direct dependent too:
  `cargo update --dry-run -p <parent>`. A newer parent often drops the
  crate. `cargo tree -i <crate>@<version> --target all` lists the parents.
- `cargo tree -e features -i <crate>@<version> --target all` shows the
  feature that turns the crate on. If no code needs that feature, turning it
  off removes the crate.
- Every other row is `hard`, for example:
  - The fix needs a new major version, or a new minor version of a `0.x`
    crate.
  - No patched version exists, as for an unmaintained crate.
  - A parent crate pins the old version.

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
3. Run the full project check for each changed workspace, for example its CI
   script or a `.cargo/config.toml` alias. It must include
   clippy with `-D warnings`, because a patch release can deprecate an API
   that the code uses.
4. Follow the project rules for other files that pin crate versions.
5. Check the update as "Breaking and behavior changes" describes. A patch
   release can also change behavior, or deprecate an API.
6. Run the script again into the scratchpad. Set each row that is gone to
   `fixed`. If an `easy` row is still there, set it to `hard`, and add its
   entry.

## 5. Commit the updates

1. Read the project rules for the commit title format and for changelog
   entries.
2. Stage only the files of this update by name: the lockfiles, and the other
   files that the project rules made you change. Do not use `git add -A`.
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
2. A fix can move a crate to a new major version, or to a new minor version
   of a `0.x` crate. If it does, read the upstream changelog. Note each behavior change
   and each break of a public API for the PR description.
3. Give the user the options, with a recommendation. The user decides.
   - a. Raise the version requirement in `Cargo.toml`, and fix the code for
     the new API.
   - b. Update or replace the parent crate that pins the old version.
   - c. Replace an unmaintained crate. The advisory often names a successor.
   - d. Accept the advisory, and leave the issue open. Add the comment to
     `## GitHub updates`, with links to the open upstream issues.
   - e. Ignore the advisory in one workspace. Add its ID to `ignore` in the
     `.cargo/audit.toml` of that workspace, with a comment that gives the
     reason. This fits a workspace that no CI audit covers, such as an
     internal tool. Only the user makes this decision.
4. Do the fix, then build and run the script again, as in step 4. Check the
   fix as "Breaking and behavior changes" describes.
5. Set the rows of the entry to `fixed`, check its box, and add the commit
   under `## Commits`.

## 7. Check again at the end

The advisory database grows while the work runs. Run the script once more
with a fresh database, and compare the table with the document.

Each new row starts again at step 3.

Check each upstream issue or PR that an open entry links, with
`gh issue view` or `gh pr view`. If one is closed or merged, its entry
starts again at step 3.

## 8. Propose issues to create

End the work with a short list of issues that the user can create. Do not
list other follow-up work.

Propose an issue for each of these:

- A fix that no issue tracks, for example a migration that removes an open
  advisory.
- A breakage that the work found but did not cause.
- A workspace with lockfile findings that no CI audit covers.

Give each issue one line: a title in the project title format, and the
reason in a few words. Create the issues only after the user approves.
