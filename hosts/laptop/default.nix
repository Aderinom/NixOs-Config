{...}: {
  imports = [
    ./power-config.nix
  ];

  myConfig.enableBluetooth = true;
}
