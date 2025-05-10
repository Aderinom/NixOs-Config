{
  config,
  vars,
  ...
}: {
  programs.starship.enable = true;
  programs.starship.enableFishIntegration = true;

  xdg.configFile."starship.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${vars.flakeRoot}/host-setup/user/home/starship/starship.toml";
}
