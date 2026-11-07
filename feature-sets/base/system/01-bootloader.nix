{lib, ...}: {
  # mkDefault, so that a machine that boots with BIOS can switch to GRUB in its hardware-configuration.nix.
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  boot.loader.systemd-boot.configurationLimit = 10; # Keep up to 10 Boot Configs from NixOs
}
