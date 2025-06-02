#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq git pywal swww
# shellcheck shell=bash

set -e

# CWD to root dir
pushd "$(dirname "$0")/.." || exit 1
rootDir=$(pwd);

#Make flake variables and hardware config not stageable
git update-index --skip-worktree hardware-configuration.nix
git update-index --skip-worktree hardware-extra-configuration.nix
git update-index --skip-worktree flake-variables.nix

# Check that ./hardware-configuration.nix was updated
if grep -q "Error: Replace Placeholder hardware-configuration.nix" "./hardware-configuration.nix"; then
    echo "You need to replace the 'hardware-configuration.nix'"
    exit 1
fi

# Check that ./flake-variables.nix was updated
res=$(nix-instantiate --eval --expr "import ./flake-variables.nix {}" --strict --json || echo "fail")
if [[ "$res" == "fail" ]]; then
    echo "flake-variables.nix must be configured"
    exit 1
fi

# Check that flake-root is correct
if [[ $(echo "$res" | jq ".flakeRoot" --raw-output) != $(pwd) ]]; then
    echo "flakeRoot in flake-variables.nix seems to be incorrect - expected $rootDir"
    exit 1
fi


echo "Going to install flake with config:"
echo "$res" | jq


read -p "Do you want to proceed with the installation? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Installation cancelled."
    exit 1
fi


# Prompt for flake_type
read -p "Enter the host type (e.g., laptop): " flake_type


username=$(echo $res | jq ".username" --raw-output);
echo "Starting install"

# Bit of hacky stuff

# Create placeholder file for hyprland colors
mkdir -p "/home/$username/.cache/wal/" 
touch "/home/$username/.cache/wal/colors-hyprland"

# Create placeholder file for hyprland-monitors
mkdir -p "/home/$username/.config/" 
touch "/home/$username/.config/monitors.conf"

# Actual install
sudo nixos-rebuild switch --flake ".#$flake_type"

# Save used flake type
echo "$flake_type" > .flake-type

# Try Generatig colorscheme and setting the background
wal -i ./assets/wallpapers/default.jpg -n

echo "Trying to set wallpaper - might fail"
swww img ./assets/wallpapers/default.jpg || true


echo 
echo "Installation completed successfully - you might want to reboot and then, enjoy!"

popd || exit 1