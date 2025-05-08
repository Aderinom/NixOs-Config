{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  logiops = pkgs.logiops;
  cfg = config.services.logiops;
in {
  options = {
    services.logiops = {
      enable = mkEnableOption (lib.mdDoc "Enables support for Logitec HID++ Devices");

      configFile = mkOption {
        type = with types; nullOr path;
        default = ./logiops.cfg;
        description = lib.mdDoc ''
          Path to the logiops config file you want to use - see https://github.com/PixlOne/logiops/wiki/Configuration for details
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.logiops = {
      enable = true;
      description = "Logitech Configuration Daemon";
      startLimitIntervalSec = 0;
      after = ["multi-user.target" "bluetooth.service"];
      wants = ["multi-user.target"];
      wantedBy = ["graphical.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${logiops}/bin/logid -c ${cfg.configFile}";
        Restart = "on-failure";
        RestartSec = "3";
        User = "root";
      };
    };
  };
}
