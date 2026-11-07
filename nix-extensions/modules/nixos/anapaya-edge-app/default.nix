# Anapaya Edge App with its privileged daemon, set up the NixOS way instead of through the .deb.
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.programs.anapaya-edge-app;
  anapaya-edge-app = pkgs.anapaya-edge-app;
in {
  options.programs.anapaya-edge-app.enable = lib.mkEnableOption "the Anapaya Edge App and its daemon";

  config = lib.mkIf cfg.enable {
    # The app talks to a privileged daemon it expects to control over systemd.
    # The .deb ships its own unit, polkit action and /opt layout; this replaces
    # all three the NixOS way.
    systemd.services.anapaya-edge-app-daemon = {
      description = "Anapaya EDGE App Daemon";
      documentation = ["https://learn.anapaya.net"];
      after = ["network.target"];
      # Deliberately not wantedBy: the app starts it on demand via daemon-ctl.
      serviceConfig = {
        Type = "simple";
        ExecStart = "${anapaya-edge-app}/bin/edge_app_daemon";
        Restart = "no";
        Environment = "RUST_LOG=debug";
        LogsDirectory = "anapaya-edge-app";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };
    };

    # The Flutter app invokes the helper by absolute path, hardcoded at build
    # time, so the package tree has to be reachable where the .deb put it.
    systemd.tmpfiles.rules = [
      "L+ /opt/anapaya/edge-app - - - - ${anapaya-edge-app}/share/anapaya-edge-app"
    ];

    # daemon-ctl runs `pkexec systemctl <verb> anapaya-edge-app-daemon`; let a
    # logged-in admin through without a password, as the vendor's action did.
    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function (action, subject) {
        if (
          action.id == "org.freedesktop.policykit.exec" &&
          action.lookup("program") == "${anapaya-edge-app.daemonCtlSystemctl}" &&
          /(^| )anapaya-edge-app-daemon( |$)/.test(action.lookup("command_line")) &&
          subject.local && subject.active && subject.isInGroup("wheel")
        ) {
          return polkit.Result.YES;
        }
      });
    '';

    environment.systemPackages = [anapaya-edge-app];
  };
}
