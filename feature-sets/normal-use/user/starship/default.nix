{
  config,
  vars,
  ...
}: {
  programs.starship.enable = true;
  programs.starship.enableFishIntegration = true;

  xdg.configFile."starship.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${vars.flakeRoot}/feature-sets/user/home/starship/starship.toml";
}
