#!/usr/bin/env bash

set -e

# CWD to root dir
pushd "$(dirname "$0")/.." || exit 1
rootDir=$(pwd);

# Check if we know what flake type was used
if [ ! -f ".flake-type" ]; then
    read -p "Enter device type (laptop, desktop, or other): " device
else
    device=$(cat .flake-type)
    echo "using flake: $device"
fi

nh os switch -H "$device" . --ask

# Overwrite used device at the end
echo "$device" > .flake-type