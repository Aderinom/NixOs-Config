{
  config,
  vars,
  ...
}: let
  currentFolder = "${vars.flakeRoot}/feature-sets/normal-use/user/chromium";
  sync_extensions = (import ./sync/extensions.nix).sync_extensions;
in {
  programs.chromium.enable = true;
  programs.chromium.extensions = [] ++ sync_extensions;

  # Sadly does not work - chrome overwrites symlink with nornmal file
  # Bookmarks magically from our git
  # xdg.configFile."chromium/Default/Bookmarks".source =
  #   config.lib.file.mkOutOfStoreSymlink "${currentFolder}/sync/Bookmarks";
}
