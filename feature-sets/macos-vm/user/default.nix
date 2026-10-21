# Registers the Claude skill for the macOS VM. See myConfig.claude.extraSkills in claude/user.
# The guard keeps the build working on a host without the claude feature set.
{
  lib,
  options,
  vars,
  ...
}: {
  config = lib.optionalAttrs (options ? myConfig.claude.extraSkills) {
    myConfig.claude.extraSkills.macos-vm = "${vars.flakeRoot}/feature-sets/macos-vm/user/claude-skill";
  };
}
