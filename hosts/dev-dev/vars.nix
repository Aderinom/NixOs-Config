# Per-host vars, merged over flake-variables.nix.
# Keep the state versions at the release this machine was installed with:
# https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
{
  # TODO: check the feature sets for the laptop.
  features = {
    desktop.hyprland = true;
    normal-use = true;
    claude = true;
  };

  # TODO: copy both state versions from the flake-variables.nix on the laptop.
  nix-state-version = throw "hosts/dev-dev/vars.nix: set nix-state-version";
  home-mgr-state-version = throw "hosts/dev-dev/vars.nix: set home-mgr-state-version";
}
