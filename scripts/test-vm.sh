#!/usr/bin/env bash
set -e

rm result *.qcow2 &> /dev/null || true

nixos-rebuild build-vm --flake .#vm;
(. $(find ./result/bin/run*)) || true

rm *.qcow2

echo 
read -p "Keep the VM? [y/n] " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    exit 0
fi

rm result