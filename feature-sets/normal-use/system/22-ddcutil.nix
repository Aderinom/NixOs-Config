{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    ddcutil
    ddcui
  ];
  hardware.i2c.enable = true;
  boot.kernelModules = ["ddcci_backlight"];
}
