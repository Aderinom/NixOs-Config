{...}: {
  programs.direnv.enable = true;

  # programs.direnv.enableFishIntegration = true;
  programs.fish = {
    enable = true;
    generateCompletions = true;
    shellInit = "
          export GITLAB_USER=\"akelbsch\"
      ";

    shellAliases = {
      ssh = "TERM=xterm-256color /run/current-system/sw/bin/ssh";

      cat = "bat -pp";
      less = "bat";

      rn = "hyprctrl dispatch exec";

      find = "fd";

      mkubectl = "minikube kubectl -- ";

      check-ops-vpn = "sudo systemctl status openvpn-ops-vpn.service";
      start-ops-vpn = "sudo systemctl start openvpn-ops-vpn.service";
      stop-ops-vpn = "sudo systemctl stop openvpn-ops-vpn.service";
    };
  };
}
