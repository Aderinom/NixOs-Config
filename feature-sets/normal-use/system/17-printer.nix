{pkgs, ...}: {
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
    };
  };

  services.printing.drivers = with pkgs; [
    gutenprint
    hplip
    splix
  ];
}
