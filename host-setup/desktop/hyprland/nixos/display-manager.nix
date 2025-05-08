{
  username,
  pkgs,
  ...
}: {
  services.displayManager.ly.enable = true;
  services.displayManager.ly.settings = {
    # # See : https://github.com/fairyglade/ly/blob/v1.0.2/res/config.ini
    clock = "%c";
    numlock = true;
    load = true;
    save = true;
    clear_password = true;
    hide_borders = true;
  };

  security.pam.services.ly.enableGnomeKeyring = true;
  programs.seahorse.enable = true; # enable the graphical frontend
}
