let
  # A bit of a specialized setup but -
  # import all the modules you want to enable here
  mods = [
    (import ./desktop/hyprland)
    (import ./normal-use)
    (import ./personal-use)
  ];
  
  getAllSystemImports = mods: builtins.concatMap (mod: mod.systemImports or []) mods;
  getAllUserImports = mods: builtins.concatMap (mod: mod.userImports or []) mods;
in {
  systemImports = getAllSystemImports mods;
  userImports = getAllUserImports mods;
}