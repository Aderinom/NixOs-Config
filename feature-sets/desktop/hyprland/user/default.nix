{inputs, ...}: {
  imports = [
    ./themes.nix
    ./keyring.nix
    ./session-variables.nix
    ./cava
    ./hyprland
    ./swaync
    ./waybar
    ./wofi
    ./pywal
    ./udiskie.nix
    ./wlogout.nix
  ];
}
