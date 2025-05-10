{
  config,
  flakeRoot,
  pkgs,
  lib,
  ...
}: let
  currentFolder = "${flakeRoot}/host-setup/user/home/vscode";
in {
  programs.vscode.enable = true;
  programs.vscode.package = pkgs.vscode.fhs;

  xdg.configFile."Code/User/keybindings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${currentFolder}/user/keybindings.json";

  xdg.configFile."Code/User/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${currentFolder}/user/settings.json";

  # On switch, run the setup-extension script with vscode in its path
  # Doesn't seem to work correcly
  # home.activation.installVSCodeExtensions = lib.hm.dag.entryAfter ["writeBoundary"] ''
  #   PATH="${pkgs.vscode.fhs}/bin:$PATH" ${currentFolder}/extensions/setup-extensions.sh > /tmp/nix-vscode-setup.log
  # '';
}
