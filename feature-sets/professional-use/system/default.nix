{...}: {
  imports = [
    ./00-packages.nix
    ./01-onepass.nix
    ./02-envfs.nix
    ./03-tailscale.nix
    ./04-virtualbox.nix
  ];
}
