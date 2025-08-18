{
  vars,
  pkgs,
  ...
}: {
  users.users.${vars.username}.extraGroups = ["wireshark"];
  programs.wireshark.enable = true;
  environment.systemPackages = [
    pkgs.wireshark
  ];
}
