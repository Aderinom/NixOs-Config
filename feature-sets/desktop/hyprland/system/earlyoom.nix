{
  services.earlyoom = {
    enable = true;
    freeSwapThreshold = 2;
    freeMemThreshold = 2;
    extraArgs = [
      "-g"
      "--avoid"
      "^(X|plasma.*|konsole|kwin|Hyprland|hyprland|Waybar|swaybg)$"
      "--prefer"
      "^(electron|libreoffice|gimp)$"
    ];
  };
}
