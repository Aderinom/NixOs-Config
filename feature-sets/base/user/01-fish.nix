{...}: {
  programs.direnv.enable = true;

  # programs.direnv.enableFishIntegration = true;

  programs.fish = {
    enable = true;
    generateCompletions = true;
    shellInit = "
        set fish_greeting
      ";

    shellAliases = {
      ssh = "TERM=xterm-256color /run/current-system/sw/bin/ssh";

      cat = "bat -pp";
      less = "bat";

      find = "fd";
    };
  };
}
