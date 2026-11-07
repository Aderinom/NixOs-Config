{
  pkgs,
  vars,
  ...
}: {
  users.users."${vars.username}".extraGroups = ["networkmanager"];
  networking = {
    networkmanager.enable = true;

    firewall.allowedTCPPorts = [
      22
      80
      443
    ];
  };

  environment.systemPackages = with pkgs; [networkmanagerapplet];
}
