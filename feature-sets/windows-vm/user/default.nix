# Registers the Claude skill for the Windows VM. See myConfig.claude.extraSkills in claude/user.
# The guard keeps the build working on a host without the claude feature set.
{
  lib,
  options,
  vars,
  ...
}: {
  config = lib.optionalAttrs (options ? myConfig.claude.extraSkills) {
    myConfig.claude.extraSkills.windows-vm = "${vars.flakeRoot}/feature-sets/windows-vm/user/claude-skill";
  };
}
