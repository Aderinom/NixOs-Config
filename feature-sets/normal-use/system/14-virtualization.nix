{
  pkgs,
  vars,
  ...
}: {
  # Add user to libvirtd group
  users.users.${vars.username}.extraGroups = ["libvirtd" "docker"];

  # Install necessary packages
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    virtio-win
    win-spice
    adwaita-icon-theme

    minikube
    lazydocker
    qemu
    quickemu
  ];

  # Docker
  virtualisation.docker.enable = true;
  networking.firewall.trustedInterfaces = ["docker0" "br-+"];

  # Quemu
  programs.virt-manager.enable = true;
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };
  services.spice-vdagentd.enable = true;
}
