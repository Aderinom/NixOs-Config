{
  pkgs,
  kbdLayout,
  ...
}: {
  environment.systemPackages = with pkgs; [
    displaylink
  ];

  # Enable Thunderbolt
  services.hardware.bolt.enable = true;

  services.xserver.enable = true;
  services.xserver.videoDrivers = ["displaylink" "modesetting"];
  services.xserver.xkb.layout = kbdLayout;

  # Enable displaylink (https://wiki.nixos.org/wiki/Displaylink)
  systemd.services.dlm.wantedBy = ["multi-user.target"];

  services.libinput.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config = {
      common.default = ["gtk"];
      hyprland.default = [
        "gtk"
        "hyprland"
      ];
    };

    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };
}
