{pkgs, ...}: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10; # Keep up to 10 Boot Configs from NixOs
  boot.kernelPackages = pkgs.linuxPackages_zen; # Optimized kernel for Desktop use
  boot.supportedFilesystems = ["ntfs"]; # Enable NTFS support
}
