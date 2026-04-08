{
  config,
  vars,
  pkgs,
  lib,
  ...
}: let
  currentFolder = "${vars.flakeRoot}/feature-sets/normal-use/user/vscode";
  vscodePkg =
    (pkgs.vscode.override (prev: {
      commandLineArgs =
        (prev.commandLineArgs or "")
        + " --enable-features=UseOzonePlatform"
        + " --ozone-platform=wayland"
        + " --enable-wayland-ime"
        + " --use-angle=vulkan";
    })).fhs;
in {
  programs.vscode.enable = true;
  programs.vscode.package = vscodePkg;

  xdg.configFile."Code/User/keybindings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${currentFolder}/user/keybindings.json";

  xdg.configFile."Code/User/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${currentFolder}/user/settings.json";

  home.file.".vscode/argv.json".source =
    config.lib.file.mkOutOfStoreSymlink "${currentFolder}/argv.json";

  # On switch, run the setup-extension script with vscode in its path
  # Doesn't seem to work correcly
  # home.activation.installVSCodeExtensions = lib.hm.dag.entryAfter ["writeBoundary"] ''
  #   PATH="${pkgs.vscode.fhs}/bin:$PATH" ${currentFolder}/extensions/setup-extensions.sh > /tmp/nix-vscode-setup.log
  # '';
}
