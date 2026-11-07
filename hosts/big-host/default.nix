{...}: {
  imports = [
    ./hardware-configuration.nix
    ./hardware.nix
  ];

  programs.anapaya-edge-app.enable = true;

  networking.firewall.interfaces.enp4s0.allowedTCPPorts = [8080];
}
