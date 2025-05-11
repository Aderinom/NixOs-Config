{
  config,
  vars,
  ...
}: {
  programs.eza.enable = true;
  programs.eza.icons = "always";
  programs.eza.enableFishIntegration = true;
  programs.eza.extraOptions = ["--group-directories-first" "--header"];

  xdg.configFile."eza/theme.yml".source =
    config.lib.file.mkOutOfStoreSymlink "${vars.flakeRoot}/feature-sets/normal-use/user/eza/theme.yml";
}
