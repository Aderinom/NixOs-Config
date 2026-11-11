#!/usr/bin/env bash
# Stages the mechanical files of the change against HEAD, and unstages the rest.
#
# A file needs a closer review if it is new, or if more than LIMIT tokens change.
# A rename changes about one token per line, so a mechanical file stays far below the limit.
set -euo pipefail

limit=${1:-30}

git diff HEAD --name-status --no-renames | while read -r status file; do
    tokens=$(git diff HEAD --word-diff=porcelain --word-diff-regex='[A-Za-z0-9_]+|[^[:space:]]' -- "$file" \
        | grep -E '^[-+][^-+]' | sed 's/^[-+]//' | grep -oE '[A-Za-z0-9_]+|[^[:space:]]' | wc -l || true)

    if [ "$status" = A ] || [ "$tokens" -gt "$limit" ]; then
        git restore --staged -- "$file"
        # A new file stays visible as a diff in the editor.
        [ "$status" = A ] && git add --intent-to-add -- "$file"
        verdict=review
    else
        git add -- "$file"
        verdict=staged
    fi

    printf '%-6s %6s tokens  %s\n' "$verdict" "$tokens" "$file"
done
