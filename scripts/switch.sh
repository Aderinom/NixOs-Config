#!/usr/bin/env bash
set -e

# nh picks hosts/<hostname> on its own.
nh os switch "$(dirname "$0")/.." --ask
