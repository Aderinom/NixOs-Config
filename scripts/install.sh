#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq git pywal swww
# shellcheck shell=bash

set -e

# CWD to root dir
pushd "$(dirname "$0")/.." || exit 1
rootDir=$(pwd);


# Flakes REQUIRE all files to be part of the git repo.
# Since some files are only meant for local use, this is a workaround to make this as nice to work with as possible.
# All files are part of the repo, but a git hook prevents committing changes to files meant for local use only.
# If a change to the local files is needed - e.g. a new variable is added, it will be added to the template files, not to the actual files.

# Install git hook to prevent committing local files
if [[ ! -f "$rootDir/.git/hooks/pre-commit" ]]; then
    echo -e "\033[1;34mInstalling git hook to prevent committing local files...\033[0m"
    ln -sf "$rootDir/scripts/git-hooks/pre-commit" "$rootDir/.git/hooks/pre-commit"
    chmod +x "$rootDir/.git/hooks/pre-commit"
fi



created_placeholder=false
# For each file in templates, check if a file with <PLACEHOLDER> exists
for file in ./scripts/templates/*; do
    filename=$(basename "$file")
    placeholder="./$filename"

    # If the file does not exist, copy the template file
    if [[ ! -f "$placeholder" ]]; then
        cp "$file" "$placeholder"
    fi
    
    # If existing file is NOT a placeholder, skip it
    if ! grep -q "<PLACEHOLDER>" "$placeholder"; then
        continue
    fi

    # Otherwise, replace the placeholder with the actual content
    cp "$file" "$placeholder"
    echo -e "\033[1;32mCopied template file:\033[0m $placeholder"
    created_placeholder=true
done    

# If any placeholder was created, notify the user
# and exit the script so they can edit the files before proceeding.
if [[ $created_placeholder == true ]]; then
    echo -e "\033[1;33mPlease edit the following files to your needs and run the install script again:\033[0m"
    for file in ./flake-variables.nix ./hardware-configuration.nix ./flake-local.nix; do
        echo "  - $file"
    done
    exit 0
fi



# Check that ./flake-variables.nix was updated
res=$(nix-instantiate --eval --expr "import ./flake-variables.nix {}" --strict --json || echo "fail")
if [[ "$res" == "fail" ]]; then
    echo -e "\033[1;31mError:\033[0m \033[1mflake-variables.nix\033[0m must be configured properly."
    echo -e "\033[1;33mPlease edit \033[1mflake-variables.nix\033[0m and run the install script again.\033[0m"
    exit 1
fi

# Check that flake-root is correct
if [[ $(echo "$res" | jq ".flakeRoot" --raw-output) != $(pwd) ]]; then
    echo -e "\033[1;31mError:\033[0m \033[1mflakeRoot\033[0m in \033[1mflake-variables.nix\033[0m seems to be incorrect."
    echo -e "  Expected: \033[1;36m$rootDir\033[0m"
    echo -e "  Found:    \033[1;36m$(echo "$res" | jq ".flakeRoot" --raw-output)\033[0m"
    echo -e "\033[1;33mPlease update \033[1mflakeRoot\033[0m in \033[1mflake-variables.nix\033[0m and run the install script again.\033[0m"
    exit 1
fi


echo -e "\n\033[1;34mGoing to install flake with config:\033[0m"
echo "$res" | jq --color-output
echo


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