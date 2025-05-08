{
  pkgs,
  host,
  ...
}: {
  networking = {
    hostName = "${host}";
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
