{
  virtualisation.lxd = {
    enable = true;
    recommendedSysctlSettings = true;
  };
  virtualisation.lxc.lxcfs.enable = true;
  networking.bridges = {
    lxdbr0.interfaces = [];
  };
  networking.localCommands = ''
    ip address add 192.168.1.1/24 dev lxdbr0
  '';
  networking.firewall.extraCommands = ''
    iptables -A INPUT -i lxdbr0 -j ACCEPT
    iptables -A FORWARD -o lxdbr0 -j ACCEPT
    iptables -A FORWARD -i lxdbr0 -j ACCEPT
    iptables -A OUTPUT -o lxdbr0 -j ACCEPT
    iptables -t nat -A POSTROUTING -s 192.168.1.0/24 ! -d 192.168.1.0/24 -j MASQUERADE
  '';
  services.dnsmasq.enable = true;

  services.dnsmasq.settings = {
    interface = "lxdbr0";
    bind-interfaces = true;
    dhcp-range = "192.168.1.10,192.168.1.200,12h";
  };
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv4.conf.default.forwarding" = true;
  };
  boot.kernelModules = ["nf_nat_ftp"];
}
