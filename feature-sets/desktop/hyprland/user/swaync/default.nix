{
  pkgs,
  vars,
  config,
  ...
}: let
  thisDir = "${vars.flakeRoot}/feature-sets/desktop/hyprland/user/swaync";
in {
  home.packages = with pkgs; [swaynotificationcenter gnome-network-displays];
  xdg.configFile."swaync/style.css".source =
    config.lib.file.mkOutOfStoreSymlink "${thisDir}/style.css";

  xdg.configFile."swaync/config.json".source =
    config.lib.file.mkOutOfStoreSymlink "${thisDir}/config.json";
}
