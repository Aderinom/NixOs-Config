# TODO: replace with the output of `nixos-generate-config --show-hardware-config` on the laptop.
{
  imports = [(throw "hosts/dev-dev/hardware-configuration.nix: copy it from the laptop")];
}
