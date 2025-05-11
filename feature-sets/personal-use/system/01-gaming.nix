{pkgs, ...}: {
  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;

  programs.steam.protontricks.enable = true;
  environment.systemPackages = with pkgs; [mangohud protonup-qt lutris bottles heroic];
}
