{
  vars,
  pkgs,
  ...
}: {
  hardware.sane.enable = true;
  hardware.sane.extraBackends = [pkgs.hplipWithPlugin];

  users.users.${vars.username}.extraGroups = ["scanner" "lp"];
}
