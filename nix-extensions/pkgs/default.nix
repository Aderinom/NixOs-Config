# Custom packages
# You can build them using 'nix build .#example'
pkgs: {
  numi-cli = pkgs.callPackage ./numi-cli.nix {};
  scarlett2-firmware = pkgs.callPackage ./scarlett2-firmware.nix {};
}
