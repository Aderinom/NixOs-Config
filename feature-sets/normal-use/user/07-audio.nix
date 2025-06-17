{pkgs, ...}: {
  home.packages = with pkgs; [
    pavucontrol
    pulsemixer
    pamixer # pulseaudio command line mixer
  ];
}
