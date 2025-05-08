{
  pkgs,
  config,
  flakeRoot,
  ...
}: let
  ensureColorTheme = pkgs.writeShellScript "pywal-init.sh" ''
    set -e
    export PATH="${pkgs.imagemagick}/bin:$PATH"
    if [ ! -f "${config.xdg.cacheHome}/wal/colors.sh" ]; then
      ${pkgs.pywal16}/bin/wal -i ${flakeRoot}/assets/wallpapers/default.jpg
      hyprctl reload
      notify-send "Made Pretty" "Created colorscheme"
    fi
  '';
in {
  # Get them pretty colors from zhe background
  home.packages = [
    pkgs.pywal16
    pkgs.imagemagick
    pkgs.colorz
  ];

  # Add our own template used by wawybar etc
  xdg.configFile."wal/templates/colors-hyprland".source = ./colors-hyprland.template;

  # Kitty integration
  programs.kitty.extraConfig = ''
    include ${config.xdg.cacheHome}/wal/colors-kitty.conf
  '';

  programs.neovim.plugins = [
    {
      plugin = pkgs.vimPlugins.pywal-nvim;
      type = "lua";
    }
  ];

  wayland.windowManager.hyprland.settings = {
    exec-once = "${ensureColorTheme} > ~/pywal.log";
  };
}
