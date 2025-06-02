{vars, ...}: let
  # Collect all enabled feature sets
  featureSets = builtins.map import vars.enabled-features;

  # Extract systemImports and userImports from each module
  systemImports = builtins.concatMap (mod: mod.systemImports or []) featureSets;
  userImports = builtins.concatMap (mod: mod.userImports or []) featureSets;
in {
  inherit systemImports userImports;
}
