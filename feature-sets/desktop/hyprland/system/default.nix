{
  inputs,
  pkgs,
  ...
}: let
  # These are only required if using the hyprland flake, rather than the version from nixpkgs
  # hyprland-nixpkgs = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  # hyprland-pkgs = inputs.hyprland.packages.${pkgs.system};
in {
  imports = [
    ./display-manager.nix
    ./keyd.nix
  ];

  # Hyprland uses unstable nixpgks - this changes the mesa driver to the one hyprland uses
  hardware.graphics = {
    enable = true;
    # package = hyprland-nixpkgs.mesa;
    enable32Bit = true;
    # package32 = hyprland-nixpkgs.pkgsi686Linux.mesa;
  };

  programs.xwayland.enable = true;

  programs.hyprland = {
    enable = true;
    # package = hyprland-pkgs.default;
    # portalPackage =
    #   hyprland-pkgs.xdg-desktop-portal-hyprland;
  };

  security.pam.services.hyprlock = {};

  services.gvfs.enable = true;
}
