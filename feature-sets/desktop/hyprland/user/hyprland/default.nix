{
  inputs,
  pkgs,
  config,
  vars,
  ...
}: let
  # hyprDarkwindowPkgs = inputs.hypr-darkwindow.packages.${pkgs.system};
  # hyprPlugins = inputs.hyprland-plugins.packages.${pkgs.system};
  # hyprLockPkgs = inputs.hyprlock.packages.${pkgs.system};
  # hyprPkgs = inputs.hyprland.packages.${pkgs.system};
  hyprDir = "${vars.flakeRoot}/feature-sets/desktop/hyprland/user/hyprland";
  scriptsDir = "${vars.flakeRoot}/feature-sets/desktop/hyprland/user/scripts";
in {
  wayland.windowManager.hyprland.enable = true;
  # wayland.windowManager.hyprland.package = hyprPkgs.default;
  wayland.windowManager.hyprland.systemd.enable = true;
  wayland.windowManager.hyprland.systemd.enableXdgAutostart = true;
  wayland.windowManager.hyprland.xwayland.enable = true;
  wayland.windowManager.hyprland.plugins = [
    pkgs.hyprlandPlugins.hyprwinwrap
  ];


  wayland.windowManager.hyprland.settings = {
    # Let hypr directly source the file from the nix flake
    source = "${hyprDir}/hyprland-dyn.conf";
    "$scriptsDir" = scriptsDir;
    env = "HYPRCURSOR_THEME,rose-pine-hyprcursor";
  };

  xdg.configFile."hypr/hyprlock.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/hyprlock.conf";

  xdg.configFile."hypr/pyprland.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/pyprland.toml";

  xdg.configFile."hypr/hypridle.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${hyprDir}/hypridle.conf";

  home.packages = with pkgs; [
    wayland
    rose-pine-hyprcursor

    nautilus
    hyprcursor
    hyprlock
    hypridle
    hyprpicker
    hyprshot
    hyprpolkitagent
    pyprland

    nwg-displays #GUI to manage displays
    nwg-look # GTK settings

    # Controls
    brightnessctl
    poweralertd

    swww # Wallpapaer backend
    wf-recorder

    cliphist
    wl-clip-persist
    wl-clipboard

    qogir-icon-theme
  ];
}
