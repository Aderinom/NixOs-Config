# Registers the Claude skill for the macOS VM. See myConfig.claude.extraSkills in claude/user.
{vars, ...}: {
  myConfig.claude.extraSkills.macos-vm = "${vars.flakeRoot}/feature-sets/macos-vm/user/claude-skill";
}
