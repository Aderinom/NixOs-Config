# Per-host vars, merged over flake-variables.nix.
# Keep the state versions at the release this machine was installed with:
# https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
{
  features = {
    desktop.hyprland = true;
    normal-use = true;
    claude = true;
    personal-use = true;
  };

  nix-state-version = "25.11";
  home-mgr-state-version = "25.05";
}
