{
  flakeRoot,
  config,
  ...
}: {
  programs.cava.enable = true;

  xdg.configFile."cava/config".source =
    config.lib.file.mkOutOfStoreSymlink "${flakeRoot}/host-setup/desktop/hyprland/home/cava/config";
}
