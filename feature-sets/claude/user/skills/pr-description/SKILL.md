---
name: pr-description
description: Write a pull request description. Use when the user asks for a PR description, PR body, or PR summary, and when you open a pull request yourself.
---

# PR description

Write a rough overview. Do not write detailed changes.

## Draft first

Write the title and the body to `_local/<branch>/PR.md`.

After the user approves the draft, open or edit the PR.

## Check the PR after a push

After you open a PR or push to it, start a background job that waits one
minute and then runs `gh pr checks <n> --repo <owner/repo>`. Report each
failed check to the user, with the error from its log.

If a check is still pending, check it again when it ends.

## Format

```
<type>: <title>

Changes:

- <change>
- <change>

Behavior changes:

- <behavior change>

BREAKING CHANGE: <what breaks, in one sentence>
- <API and its new shape>
```

Rules:

- Title: conventional commit style, lowercase, one line. Drop the title if
  the user only wants the body.
- `Changes:`: always present, followed by a blank line.
- One change per list item. Use a `- ` markdown list. No sub-lists. No blank
  lines between items.
- 2 to 5 items. Group small edits into one item.
- 15 words per item at most.
- One clause per item. No relative clause. No second sentence.
- Do not write "which", "so that", "and also", or "including".
- Start each item with a past tense verb: Replaced, Added, Migrated,
  Implemented, Removed, Fixed.
- Name the component or type. Do not name single files, functions, or line
  counts. Do not explain how the component works.
- Leave out behavior, caching, defaults, limits, and reasons. The reviewer
  reads the diff for those.
- No sections for testing, motivation, or screenshots, unless the user asks
  for them.
- Write crate names, paths, and code identifiers in backticks, for example
  `scion-stack` or `ScionTxtDnsResolver::builder`.
- Never add an attribution footer. Never write
  `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

Rules for `Behavior changes:` and the `BREAKING CHANGE:` footer:

- If a caller, a user, or an operator sees a different result, add
  `Behavior changes:`. Name the component and the new behavior.
- Before you decide that nothing breaks, check each changed dependency of a
  public crate.
- If a `pub use` re-exports the dependency, a public type implements one of
  its traits, or a public signature uses its types, the change breaks the
  public API.
- If a dependency change crosses a major version, or a minor version of a
  `0.x` crate, it counts.
- If a dependency change turns a feature off, it counts too.
- If the change breaks a public API, end the message with a
  `BREAKING CHANGE:` footer, as Conventional Commits defines it. Nothing
  follows the footer.
- The footer starts with one sentence about what breaks. Then name each API
  that breaks, and its new shape, one item per line.
- If the message has the footer, mark the conventional title with `!` before
  the colon, for example `fix(deps)!: <title>`.
- If a section has no item, leave it out.
- One point per item, 15 words at most. Write each item as a statement in
  the present tense, about the state after the merge.

Example:

```
Behavior changes:

- Connect clients and servers no longer accept zstd compression

BREAKING CHANGE: scion-stack moves to hickory 0.26.
- ScionTxtDnsResolver::from_builder takes ResolverBuilder<TokioRuntimeProvider> from hickory 0.26
```

## Examples

```
refactor: fully replace scion-proto with sciparse

Changes:

- Replaced scion-proto with sciparse in the SCION endhost SDK and downstream tools
- Migrated path, address, and packet types to the sciparse API
- Changed most usages of ScionSocketAddr to ScionSocketIpAddr
```

```
Changes:

- Replaced scion-proto in segment-lister
```

```
Changes:

- Fully replaced the scion-proto dependency from endhost-api models
- Replaced many instances of scion-proto IsdAsn usage
- Implemented conversion functions from scion-proto to sciparse
- Added some missing functions in sciparse
```

## Too much detail

Wrong. The items explain the behavior:

```
- Added a DnsManager to the WAP control plane. It caches TSAR resolutions as the union of all DNS answers, refreshes a name on request, and also caches answers without SCION addresses and failed lookups.
- Implemented the ResolveDomain endpoint, which returns the gateway ISD-ASes for a <wap-namespace>.<customer-domain> name, and renamed the RPC from resolveDomain to ResolveDomain.
```

Right. The items name the change only:

```
- Added a DnsManager to the WAP control plane
- Implemented the ResolveDomain endpoint
```
