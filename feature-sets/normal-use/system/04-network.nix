{
  pkgs,
  vars,
  ...
}: {

  users.users."${vars.username}".extraGroups = ["networkmanager"];
  networking = {
    hostName = "${vars.host}";
    networkmanager.enable = true;
  
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
      "8.8.4.4"
    ];

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
      ];
    };
  };

  environment.systemPackages = with pkgs; [networkmanagerapplet];
}
