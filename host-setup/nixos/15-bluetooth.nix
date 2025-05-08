{
  pkgs,
  config,
  lib,
  ...
}:
with lib; {
  options.myConfig.enableBluetooth = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Bluetooth.";
  };

  config = mkIf config.myConfig.enableBluetooth {
    services.blueman.enable = true;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      package = pkgs.bluez;

      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
        Policy = {
          AutoEnable = "true";
        };
      };
    };
  };
}
