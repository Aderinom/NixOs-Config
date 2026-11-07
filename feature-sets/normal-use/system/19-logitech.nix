{inputs, ...}: {
  imports = [
    inputs.solaar.nixosModules.default
  ];
  services.solaar.enable = true;
  services.logiops.enable = true; # Logitech HID driver
}
