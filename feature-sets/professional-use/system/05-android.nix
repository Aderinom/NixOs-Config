{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    androidsdk
    android-tools
    android-studio-full
  ];

  programs.adb.enable = true;
  users.users.akelbsch.extraGroups = ["kvm" "adbusers"];

  services.udev.packages = [
    pkgs.android-udev-rules
  ];
}
