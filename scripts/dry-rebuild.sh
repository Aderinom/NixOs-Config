#!/usr/bin/env bash

nixos-rebuild dry-build --flake "$(dirname "$0")/..#${1:-$(hostname)}"
