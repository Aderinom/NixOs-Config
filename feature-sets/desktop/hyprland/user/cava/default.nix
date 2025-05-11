{
  vars,
  config,
  ...
}: {
  programs.cava.enable = true;

  xdg.configFile."cava/config".source =
    config.lib.file.mkOutOfStoreSymlink "${vars.flakeRoot}/feature-sets/desktop/hyprland/user/cava/config";
}
