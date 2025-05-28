#! /usr/bin/env bash
set -e


dir=$(dirname "$0")
pushd "$dir" || exit 1


outFile="./sync/extensions.nix";
profile="Default"
configFolder="${XDG_CONFIG_HOME:-$HOME/.config}/chromium/$profile/"

# Get all installed extensions
installedExtensions=$(ls $configFolder/Extensions)

echo "" > "$outFile"

for extension in $installedExtensions; do 
    manifest="$(find "$configFolder/Extensions/$extension/" -name manifest.json)"
    name="$(cat "$manifest" | jq ".short_name // .name" --raw-output)";

    echo "($extension) Name: $name"
    echo "    {id = \"$extension\";} #Extension: $name" >> "$outFile"
done

result="$(cat "$outFile")"
echo "{
  sync_extensions = [$result
  ];
}" > "$outFile"




