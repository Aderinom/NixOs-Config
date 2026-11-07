{pkgs, ...}: {
  hardware.firmware = [pkgs.scarlett2-firmware];
  environment.systemPackages = with pkgs; [
    scarlett2-firmware
  ];
}
