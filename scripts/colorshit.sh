#!/usr/bin/env bash

# Source the color values from the wal cache
source ~/.cache/wal/colors.sh

# Define the output file path
output_file="$HOME/.cache/wal/colors-hyprland"

# Write the color values to the file
cat <<EOL > "$output_file"
\$wallpaper = /home/akelbsch/.nixos-config/assets/wallpapers/alena-aenami-serenity-1k.jpg
\$foregroundCol = 0x${color7#"#"}
\$backgroundCol = 0x${color0#"#"}
\$color0 = 0x${color0#"#"}
\$color1 = 0x${color1#"#"}
\$color2 = 0x${color2#"#"}
\$color3 = 0x${color3#"#"}
\$color4 = 0x${color4#"#"}
\$color5 = 0x${color5#"#"}
\$color6 = 0x${color6#"#"}
\$color7 = 0x${color7#"#"}
\$color8 = 0x${color8#"#"}
\$color9 = 0x${color9#"#"}
\$color10 = 0x${color10#"#"}
\$color11 = 0x${color11#"#"}
\$color12 = 0x${color12#"#"}
\$color13 = 0x${color13#"#"}
\$color14 = 0x${color14#"#"}
\$color15 = 0x${color15#"#"}
EOL

echo "Colors have been written to $output_file"
