{
  config,
  lib,
  pkgs,
  vars,
  ...
}: let
  json = pkgs.formats.json {};
  userFolder = "${vars.flakeRoot}/feature-sets/claude/user";
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
        path = "${userFolder}/plugins";
      };
      enabledPlugins."text-rules@local" = true;
      # The text-rules hook agent needs these, and they sit outside every project.
      # A Read allow rule must match both the link path and its target. The leading / of
      # an absolute path after Read(/ makes //, which anchors the path at the filesystem root.
      permissions.allow = [
        "Read(~/.claude/rules/**)"
        "Read(/${userFolder}/**)"
        "Bash(${userFolder}/plugins/text-rules/extract.sh *)"
      ];
    };

    environment.etc."claude-code/managed-settings.json".source =
      json.generate "managed-settings.json" config.myConfig.claude.managedSettings;
  };
}
