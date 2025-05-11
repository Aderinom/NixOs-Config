# Config Yoinked from : <https://github.com/elifouts/Dotfiles/blob/main/.config/waybar/style.css>
{
  vars,
  config,
  pkgs,
  ...
}: let
  configDir = "${vars.flakeRoot}/feature-sets/desktop/hyprland/user/waybar/";
in {
  programs.waybar = {
    enable = true;
  };

  programs.waybar.package = pkgs.waybar.overrideAttrs (oa: {
    mesonFlags = (oa.mesonFlags or []) ++ ["-Dexperimental=true"];
  });

  # Just use the configs directly, rather than having to rebuild on change
  xdg.configFile."waybar/config".
    source = config.lib.file.mkOutOfStoreSymlink "${configDir}/config";

  xdg.configFile."waybar/style.css".
    source = config.lib.file.mkOutOfStoreSymlink "${configDir}/style.css";
}
