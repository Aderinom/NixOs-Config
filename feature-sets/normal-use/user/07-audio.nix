{pkgs, ...}: {
  home.packages = with pkgs; [
    pulseaudioFull
    pavucontrol
    pulsemixer
    pamixer # pulseaudio command line mixer
    scarlett2
  ];
}
