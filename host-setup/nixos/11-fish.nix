{pkgs, ...}: {
  users.defaultUserShell = pkgs.fish;

  # Disable this cause it takes really long
  documentation.man.generateCaches = false;

  programs.nix-index.enable = true;
  programs.ssh.startAgent = true;
  programs.fish = {
    enable = true;

    shellAliases = {
      cat = "bat -pp";
      less = "bat";

      rn = "nohup";
      find = "fd";

      ls = "eza --icons=always --group-directories-first";
      ssh = "TERM=xterm-256color /run/current-system/sw/bin/ssh";
    };
  };

  environment.systemPackages = with pkgs; [
    eza
    fd
    bat
  ];
}
