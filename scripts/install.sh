#!/usr/bin/env nix-shell
#!nix-shell -i bash -p git pywal awww
# shellcheck shell=bash

# First install of a host: ./scripts/install.sh <host>
# hosts/<host>/ must exist with its vars.nix and hardware-configuration.nix.

set -e

pushd "$(dirname "$0")/.." || exit 1

host="$1"
if [[ -z "$host" || ! -d "hosts/$host" ]]; then
    echo -e "\033[1;31mError:\033[0m usage: $0 <host>, where hosts/<host>/ exists"
    exit 1
fi

username=$(nix-instantiate --eval --strict --expr "(import ./flake-variables.nix {}).username" | tr -d '"')

# Hyprland reads these files before pywal and the monitor setup write them.
mkdir -p "/home/$username/.cache/wal/"
touch "/home/$username/.cache/wal/colors-hyprland"
mkdir -p "/home/$username/.config/"
touch "/home/$username/.config/monitors.conf"

sudo nixos-rebuild switch --flake ".#$host"

wal -i ./assets/wallpapers/default.jpg -n

echo "Trying to set wallpaper - might fail"
awww img ./assets/wallpapers/default.jpg || true

echo
echo "Installation completed successfully - you might want to reboot and then, enjoy!"

popd || exit 1
