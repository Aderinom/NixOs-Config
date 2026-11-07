{
  pkgs,
  vars,
  ...
}: {
  # environment.systemPackages = with pkgs; [
  # ];

  # Enable Thunderbolt
  services.hardware.bolt.enable = true;

  services.xserver.enable = true;
  services.xserver.videoDrivers =
    (
      if vars.uses-nvidia-gpu
      then ["nvidia"]
      else []
    )
    ++ ["modesetting"];

  services.xserver.xkb.layout = vars.kbdLayout;

  # Enable displaylink (https://wiki.nixos.org/wiki/Displaylink)
  # systemd.services.dlm.wantedBy = ["multi-user.target"];

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

    extraPortals = [
      pkgs.xdg-desktop-portal
      pkgs.xdg-desktop-portal-gtk
    ];
  };
}
