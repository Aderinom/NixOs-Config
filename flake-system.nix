# The Underlying default configuration for any system
{vars, ...}: let
  enabledModules = import ./feature-sets/enabled.nix {inherit vars;};
in {
  imports = enabledModules.systemImports;
}
