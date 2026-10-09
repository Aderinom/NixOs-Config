# Registers the Claude skill for the macOS VM. See myConfig.claude.extraSkills in normal-use/user/claude.
{vars, ...}: {
  myConfig.claude.extraSkills.macos-vm = "${vars.flakeRoot}/feature-sets/macos-vm/user/claude-skill";
}
