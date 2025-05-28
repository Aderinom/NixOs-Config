# Flake wide nix settings to apply
{
  pkgs,
  inputs,
  outputs,
  vars,
  ...
}: {
  system.stateVersion = vars.nix-state-version;

  imports = [
    outputs.my.modules.nixos # Load our custom modues
  ];

  nixpkgs = {
    overlays = [
      inputs.nur.overlays.default
      outputs.my.overlays.additions # Adds our custom packages to nixpkgs
      outputs.my.overlays.modifications # Applies our overlays
      outputs.my.overlays.unstable-packages # Allows to  use unstable packages through pkgs.unstable
    ];
  };

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://nix-gaming.cachix.org"
        "https://hyprland.cachix.org"
        "https://ghostty.cachix.org"
      ];
      trusted-public-keys = [
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      ];
    };
  };

  environment.variables = {
    NIXPKGS_ALLOW_UNFREE = 1;
  };

  environment.systemPackages = with pkgs; [
    wget
    git
  ];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.permittedInsecurePackages = [
    "electron-33.4.11"
  ];
}
