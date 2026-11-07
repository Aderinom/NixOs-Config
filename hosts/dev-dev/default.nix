{...}: {
  imports = [
    ./hardware-configuration.nix
    ./power-config.nix
  ];

  myConfig.enableBluetooth = true;
}
