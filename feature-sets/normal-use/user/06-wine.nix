{pkgs, ...}: {
  # Wine
  home.packages = with pkgs; [
    winetricks
    wineWowPackages.wayland
  ];
}
