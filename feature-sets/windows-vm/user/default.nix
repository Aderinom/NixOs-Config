# Registers the Claude skill for the Windows VM. See myConfig.claude.extraSkills in claude/user.
{vars, ...}: {
  myConfig.claude.extraSkills.windows-vm = "${vars.flakeRoot}/feature-sets/windows-vm/user/claude-skill";
}
