# Per-host vars, merged over flake-variables.nix.
{
  features = {
    desktop.hyprland = true;
    normal-use = true;
  };

  nix-state-version = "25.11";
  home-mgr-state-version = "25.05";
}
