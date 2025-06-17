{pkgs, ...}: {
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.printing.drivers = with pkgs; [
    gutenprint
    hplip
    splix
  ];
}
