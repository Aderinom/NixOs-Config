{pkgs, ...}: {
  home.packages = with pkgs; [
    discord
    unstable.telegram-desktop
    prismlauncher
    nexusmods-app-unfree
  ];
}
