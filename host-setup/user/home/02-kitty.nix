{pkgs, ...}: {
  programs.kitty.enable = true;
  programs.kitty.themeFile = "Brogrammer";
  programs.kitty.shellIntegration.enableFishIntegration = true;
  programs.kitty.extraConfig = "
    enabled_layouts grid

    # Make ctrl + backspace work
    map ctrl+backspace send_text all \\x17

    # Broadcast
    map F1 launch --allow-remote-control kitty +kitten broadcast

    # Move to the window in given direction
    map alt+left neighboring_window left
    map alt+right neighboring_window right
    map alt+up neighboring_window up
    map alt+down neighboring_window down

    # Splitting windows
    map alt+s launch
    map alt+w close_window

    # Don't annoy me on close
    confirm_os_window_close 0
  ";

  home.packages = with pkgs; [
    kitty-img
  ];
}
#         export GITLAB_USER=\"akelbsch\"

