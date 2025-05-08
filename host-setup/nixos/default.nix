{...}: {
  imports = [
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
    ./97-programs.nix
    ./98-services.nix
    ./99-state-version.nix
  ];
}
