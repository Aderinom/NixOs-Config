{
  config,
  lib,
  pkgs,
  vars,
  ...
}: let
  json = pkgs.formats.json {};
in {
  options.myConfig.claude.managedSettings = lib.mkOption {
    type = json.type;
    default = {};
    example = {enabledPlugins."foo@local" = true;};
    description = ''
      Claude Code managed settings. Every feature set can add keys, and they merge into one file.
      Claude Code never writes to it, and no user setting overrides a key in it.
    '';
  };

  config = {
    myConfig.claude.managedSettings = {
      extraKnownMarketplaces.local.source = {
        source = "directory";
        path = "${vars.flakeRoot}/feature-sets/claude/user/plugins";
      };
      enabledPlugins."text-rules@local" = true;
    };

    environment.etc."claude-code/managed-settings.json".source =
      json.generate "managed-settings.json" config.myConfig.claude.managedSettings;
  };
}
