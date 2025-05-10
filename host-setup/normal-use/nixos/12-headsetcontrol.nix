{pkgs, ...}: {
  services.udev.packages = [
    pkgs.headsetcontrol
  ];

  environment.systemPackages = with pkgs; [
    headsetcontrol
    headset-charge-indicator
  ];
}
