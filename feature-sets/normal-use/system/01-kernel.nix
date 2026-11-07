{pkgs, ...}: {
  boot.kernelPackages = pkgs.linuxPackages_zen; # Optimized kernel for Desktop use
  boot.supportedFilesystems = ["ntfs"]; # Enable NTFS support
}
