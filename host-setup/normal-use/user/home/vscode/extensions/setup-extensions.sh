#! /usr/bin/env bash

# This script checks if the extensions in "list" are installed
# and installs them if not.

function log() {
    echo "$(date) - $1"
}

if ! command -v code >/dev/null 2>&1; then
    log "Did not find code - skipping extensions install"
    exit 0
fi

dir=$(dirname "$0")
pushd "$dir" || exit 1


installedExtensions=$(code --list-extensions)

count=0
while IFS= read -r ext; do
    if echo "$ext" | grep -Eq '^\s*$|^\s*#'; then
        continue
    fi

    if ! echo $installedExtensions | grep -q "$ext"; then
        log "Extension '$ext' is not installed. Installing"
        count=$(($count + 1))
        code --install-extension $ext --force
        if [ $? -eq 0 ]; then
            log "Extension '$ext' installed successfully"
        else
            log "Failed to install extension '$ext'"
        fi
    fi
done < "default-extensions"

log "Total installed extensions: $count"

popd || exit 1



