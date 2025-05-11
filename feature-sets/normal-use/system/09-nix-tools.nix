{
  pkgs,
  vars,
  ...
}: {
  programs.nh = {
    enable = true;
    # Garbage Collect Nix Builds
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 5";
    };
    flake = "/home/${vars.username}/.nixos-config";
  };

  environment.systemPackages = with pkgs; [
    nix-output-monitor
    nvd
    nixd
    alejandra
    nix
  ];
}
