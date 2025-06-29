{pkgs, ...}: {
  home.packages = with pkgs; [
    whatsapp-for-linux
    discord
    telegram-desktop
  ];
}
