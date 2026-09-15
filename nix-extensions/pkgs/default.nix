# Custom packages
# You can build them using 'nix build .#example'
pkgs: {
  claude-box = pkgs.callPackage ./claude-box {};
  numi-cli = pkgs.callPackage ./numi-cli.nix {};
  scarlett2-firmware = pkgs.callPackage ./scarlett2-firmware.nix {};
}
