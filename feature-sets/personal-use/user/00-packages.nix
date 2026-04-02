{pkgs, ...}: {
  home.packages = with pkgs; [
    whatsapp-for-linux
    discord
    unstable.telegram-desktop
    prismlauncher
    nexusmods-app-unfree
  ];
}
