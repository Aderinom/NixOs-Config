{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    openssl.dev
    pkg-config
    alsa-utils

    pkg-config
    webkitgtk_4_1
    librsvg
  ];
}
