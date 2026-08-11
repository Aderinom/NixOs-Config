{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.spt-additions
    pkgs.spt-server
    pkgs.spt-launcher
  ];
}
