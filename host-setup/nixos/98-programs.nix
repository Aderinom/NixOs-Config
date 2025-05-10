{vars, ...}: {
  users.users.${vars.username}.extraGroups = ["wireshark"];
  programs.wireshark.enable = true;
}
