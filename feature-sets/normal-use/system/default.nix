{...}: {
  imports = [
    ./chromium
    ./00-packages.nix
    ./01-bootloader.nix
    ./02-hardware.nix
    ./03-locale.nix
    ./04-network.nix
    ./05-systemd.nix
    ./06-display.nix
    ./07-audio.nix
    ./08-security.nix
    ./09-nix-tools.nix
    ./10-nix-ld.nix
    ./11-fish.nix
    ./12-headsetcontrol.nix
    ./13-fonts.nix
    ./14-virtualization.nix
    ./15-bluetooth.nix
    ./16-usb.nix
    ./17-printer.nix
    ./18-scanner.nix
    ./19-logitech.nix
    ./98-programs.nix
    ./99-services.nix
  ];
}
