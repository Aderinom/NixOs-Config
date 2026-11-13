{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  programs.anapaya-edge-app.enable = true;

  networking.hosts = {
    "127.0.0.1" = ["localhost"];
    "::1" = [];
    "127.0.0.2" = ["fwafawawfafw"];
  };

  users.users."akelbsch".extraGroups = ["kvm" "adbusers"];

  home-manager.users.akelbsch.home.file.".local/share/icons/breeze_cursors" = {
    source = "${pkgs.kdePackages.breeze}/share/icons/breeze_cursors/";
    recursive = true;
  };

  home-manager.users.akelbsch.xdg.mimeApps.defaultApplications = lib.mapAttrs (_: lib.mkForce) {
    "text/html" = "chromium-browser.desktop";
    "x-scheme-handler/http" = "chromium-browser.desktop";
    "x-scheme-handler/https" = "chromium-browser.desktop";
    "x-scheme-handler/about" = "chromium-browser.desktop";
    "x-scheme-handler/unknown" = "chromium-browser.desktop";
  };

  systemd.tmpfiles.rules = [
    "L+ /opt/google/chrome/chrome - - - - ${pkgs.chromium}/bin/chromium"
  ];

  environment.systemPackages = [
    pkgs.distrobox
    pkgs.graphite-cli
    pkgs.cue
    pkgs.cuelsp
    pkgs.sccache
  ];

  environment.variables = {
    RUSTC_WRAPPER = "sccache";
  };

  networking.firewall.interfaces.enp2s0.allowedTCPPorts = [22];
  networking.interfaces.enp2s0.ipv4.routes = [
    {
      address = "10.100.100.0";
      via = "172.30.200.130";
      prefixLength = 24;
    }
  ];

  security.wrappers = {
    # a setuid root program
    polkit = {
      setuid = true;
      owner = "root";
      group = "root";
      source = "${pkgs.polkit}/bin/pkexec";
    };
  };

  # IceWM desktop on a VNC-only X server, separate from the Hyprland session.
  # No VNC auth: reach it only through an SSH tunnel, e.g. ssh -L 5900:127.0.0.1:5900
  users.users.akelbsch.linger = true;
  home-manager.users.akelbsch.systemd.user.services.icewm-vnc = {
    Unit.Description = "IceWM desktop on Xvnc";
    Service = {
      # bash -l: lingering units start without a login, so this loads the system environment.
      ExecStart = "${pkgs.bash}/bin/bash -l ${pkgs.writeShellScript "icewm-vnc" ''
        ${pkgs.tigervnc}/bin/Xvnc :5 -localhost -rfbport 5900 -SecurityTypes None -geometry 1920x1080 -depth 24 &
        while [ ! -e /tmp/.X11-unix/X5 ]; do sleep 0.1; done
        export DISPLAY=:5
        unset WAYLAND_DISPLAY
        export PATH=${lib.makeBinPath [pkgs.icewm pkgs.xterm]}:$PATH
        exec dbus-run-session icewm-session
      ''}";
      Restart = "on-failure";
    };
    Install.WantedBy = ["default.target"];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    openFirewall = true; # UDP 5353; default is already true
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
}
