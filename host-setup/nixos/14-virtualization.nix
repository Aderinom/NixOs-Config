{
  pkgs,
  username,
  ...
}: {
  # Add user to libvirtd group
  users.users.${username}.extraGroups = ["libvirtd" "docker"];

  # Install necessary packages
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    win-virtio
    win-spice
    adwaita-icon-theme

    minikube
    lazydocker
    qemu
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
        ovmf.enable = true;
        ovmf.packages = [pkgs.OVMFFull.fd];
      };
    };
    spiceUSBRedirection.enable = true;
  };
  services.spice-vdagentd.enable = true;
}
