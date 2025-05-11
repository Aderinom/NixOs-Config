{
  ...
}: {
  programs.wofi.enable = true;

  # NOTE: Wofi seems to not follow symlinks - so we need to actually pass the config
  xdg.configFile."wofi/config".source = ./config;
  xdg.configFile."wofi/style.css".source = ./style.css;
}
