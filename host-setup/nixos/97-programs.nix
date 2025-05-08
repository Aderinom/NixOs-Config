{
  pkgs,
  username,
  ...
}: {
  users.users.${username}.extraGroups = ["wireshark"];
  programs.wireshark.enable = true;

  environment.systemPackages = with pkgs; [
    vscode.fhs
  ];
}
