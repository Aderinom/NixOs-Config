# The Underlying default configuration for any system
{
  lib,
  vars,
  ...
}: {
  imports = (import ./feature-sets {inherit lib vars;}).systemModules;
}
