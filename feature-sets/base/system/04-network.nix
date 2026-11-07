{vars, ...}: {
  networking.nftables.enable = true;
  networking = {
    hostName = "${vars.host}";

    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
      "8.8.4.4"
    ];

    firewall.enable = true;
  };
}
