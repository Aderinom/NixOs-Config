---
name: pr-description
description: Write a pull request description. Use when the user asks for a PR description, PR body, or PR summary, and when you open a pull request yourself.
---

# PR description

Write a rough overview. Do not write detailed changes.

## Format

```
<type>: <title>

Changes:

- <change>
- <change>
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
- No sections for testing, motivation, screenshots, or breaking changes,
  unless the user asks for them.
- Never add an attribution footer. Never write
  `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

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
