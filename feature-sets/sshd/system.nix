{vars, ...}: {
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      AllowUsers = [vars.username];
      UseDns = false;
      X11Forwarding = false;
      PermitRootLogin = "no"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
      PasswordAuthentication = false;
      UsePAM = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Allow SSH connections over Tailscale
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [22];

  users.users.${vars.username} = {
    openssh.authorizedKeys.keys = vars.ssh-authorized-keys;
  };
}
