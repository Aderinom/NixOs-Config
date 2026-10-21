# Every feature set, imported always and turned on with myConfig.features.<path>.enable.
# A feature set is a folder with a default.nix that returns systemImports and userImports.
# Its option defaults to the value at its path in vars.features, for example vars.features.desktop.hyprland.
{
  lib,
  vars,
}: let
  featureSets = findFeatureSets ./. [];

  # Declare one enable option per feature set.
  optionsModule = {
    options.myConfig.features = lib.foldl' lib.recursiveUpdate {} (map (fs:
      lib.setAttrByPath (fs.at ++ ["enable"]) (lib.mkOption {
        type = lib.types.bool;
        default = lib.attrByPath fs.at false vars.features;
        description = "Turn on the feature set ${lib.concatStringsSep "/" fs.at}.";
      }))
    featureSets);

    # A typo in vars.features would otherwise turn nothing on without an error.
    config.assertions =
      map (at: {
        assertion = builtins.elem at (map (fs: fs.at) featureSets);
        message = "vars.features.${lib.concatStringsSep "." at} is not a feature set.";
      })
      (leavesOf vars.features []);
  };

  # The attribute paths of the values in a nested attribute set.
  leavesOf = attrs: at:
    lib.concatLists (lib.mapAttrsToList (name: value:
      if builtins.isAttrs value
      then leavesOf value (at ++ [name])
      else [(at ++ [name])])
    attrs);

  # Gate the modules of each feature set by its option.
  modulesOf = side: argName:
    lib.concatMap (fs: let
      isOn = args: lib.getAttrFromPath (["myConfig" "features"] ++ fs.at ++ ["enable"]) args.${argName};
    in
      map (gate isOn argName) ((import fs.path).${side} or []))
    featureSets;

  # A folder with a default.nix is a feature set. A folder without one, like desktop/, holds more of them.
  findFeatureSets = dir: at:
    lib.concatLists (lib.mapAttrsToList (name: type: let
      path = dir + "/${name}";
    in
      if type != "directory"
      then []
      else if builtins.pathExists (path + "/default.nix")
      then [{inherit path; at = at ++ [name];}]
      else findFeatureSets path (at ++ [name]))
    (builtins.readDir dir));

  # Wrap a module and its imports so that their config applies only if isOn is true. The options stay
  # declared, so another feature set can set them while this one is off. argName names the module
  # argument that holds the NixOS config: config in NixOS, osConfig in home-manager.
  gate = isOn: argName: module:
  # An import that is not a path comes from a flake input and has its own enable options.
    if !(builtins.isPath module)
    then module
    else let
      file =
        if lib.pathIsDirectory module
        then module + "/default.nix"
        else module;
      raw = import file;
      rawArgs =
        if lib.isFunction raw
        then lib.functionArgs raw
        else {};

      wrap = args: let
        m =
          if lib.isFunction raw
          then raw (builtins.intersectAttrs rawArgs args)
          else raw;
        # A module without config and options is all config, apart from these keys.
        config =
          if m ? config || m ? options
          then m.config or {}
          else removeAttrs m ["imports" "disabledModules" "_file" "key"];
      in {
        _file = file;
        key = toString file;
        imports = map (gate isOn argName) (m.imports or []);
        disabledModules = m.disabledModules or [];
        options = m.options or {};
        config = lib.mkIf (isOn args) config;
      };
    in
      lib.setFunctionArgs wrap (rawArgs // {${argName} = false;});
in {
  systemModules = [optionsModule] ++ modulesOf "systemImports" "config";
  userModules = modulesOf "userImports" "osConfig";
}
