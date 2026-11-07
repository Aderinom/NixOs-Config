{...}: {
  imports = [
    ./01-bootloader.nix
    ./03-locale.nix
    ./04-network.nix
    ./08-security.nix
    ./09-nix-tools.nix
    ./10-nix-compat.nix
    ./11-fish.nix
    ./15-bluetooth.nix
    ./16-usb.nix
    ./20-tailscale.nix
  ];
}
