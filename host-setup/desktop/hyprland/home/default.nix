{inputs, ...}: {
  imports = [
    # inputs.hyprland.homeManagerModules.default
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
