{pkgs, ...}: {
  services.desktopManager.plasma6.enable = true;

  environment.systemPackages = with pkgs; [
    kdePackages.partitionmanager
    kdePackages.kio-admin
    kdePackages.kcalc
    kdePackages.qtquick3d
    kdePackages.sddm-kcm
    kdePackages.plasma-browser-integration
    # SDDM Theme
    (pkgs.callPackage ./sddm-astronaut-theme.nix {
      theme = "astronaut";
      themeConfig = {
        General = {
          HeaderText = "Hello there!";
          Background = "";
          FontSize = "10.0";
        };
      };
    })
  ];

  # SDDM
  services.displayManager.sddm = {
    theme = "sddm-astronaut-theme";
    enable = true;
    autoNumlock = true;
    enableHidpi = true;
    wayland.enable = true;
    extraPackages = with pkgs; [
      #Reqiored for theme
      kdePackages.qtsvg
      kdePackages.qtmultimedia
      kdePackages.qtvirtualkeyboard
    ];
  };
  security.pam.services.sddm.enableKwallet = true;
}
