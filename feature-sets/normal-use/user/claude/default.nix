{
  config,
  vars,
  ...
}: let
  currentFolder = "${vars.flakeRoot}/feature-sets/normal-use/user/claude";
in {
  # Claude Code's user-level instructions, kept in this repo.
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${currentFolder}/CLAUDE.md";

  home.file.".claude/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${currentFolder}/skills";

  home.file.".claude/agents".source =
    config.lib.file.mkOutOfStoreSymlink "${currentFolder}/agents";

  home.file.".claude/commands".source =
    config.lib.file.mkOutOfStoreSymlink "${currentFolder}/commands";
}
