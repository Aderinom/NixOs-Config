{pkgs, ...}: {
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  home.sessionVariables = {
    GTK_THEME = "Adwaita:dark";

    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    QT_STYLE_OVERRIDE = "Adwaita-dark";
  };

  gtk.enable = true;
  gtk.theme.name = "Adwaita-Dark";
  gtk.theme.package = pkgs.gnome-themes-extra;
  gtk.cursorTheme.name = "Qogir";
  gtk.iconTheme.name = "Qogir";

  gtk.gtk3.extraConfig = {
    Settings = ''
      gtk-application-prefer-dark-theme=1
    '';
  };

  gtk.gtk4.extraConfig = {
    Settings = ''
      gtk-application-prefer-dark-theme=1
    '';
  };

  qt.enable = true;
  qt.platformTheme.name = "gtk";
}
