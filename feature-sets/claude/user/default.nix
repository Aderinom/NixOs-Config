{
  config,
  lib,
  vars,
  ...
}: let
  currentFolder = "${vars.flakeRoot}/feature-sets/claude/user";
  skillsFolder = "${currentFolder}/skills";
  extraSkills = config.myConfig.claude.extraSkills;
  # Names of the links that the last activation created, so that the next one can remove dropped ones.
  stateFile = "${config.xdg.stateHome}/claude-extra-skills";
  gitExclude = "${vars.flakeRoot}/.git/info/exclude";
  excludeBegin = "# BEGIN claude extra skills (home-manager)";
  excludeEnd = "# END claude extra skills (home-manager)";
  skillsRepoPath = lib.removePrefix "${vars.flakeRoot}/" skillsFolder;
in {
  options.myConfig.claude.extraSkills = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {};
    example = {windows-vm = "/home/me/.nixos-config/feature-sets/windows-vm/user/claude-skill";};
    description = ''
      Skills that other feature sets add, as skill name -> absolute path of the skill folder in the repo.
      Activation links each one into the skills folder and git-excludes the link.
      If a feature set drops out, the next activation removes its link.
    '';
  };

  config = {
    # Claude Code's user-level instructions, kept in this repo.
    home.file.".claude/CLAUDE.md".source =
      config.lib.file.mkOutOfStoreSymlink "${currentFolder}/CLAUDE.md";

    home.file.".claude/skills".source =
      config.lib.file.mkOutOfStoreSymlink skillsFolder;

    home.file.".claude/agents".source =
      config.lib.file.mkOutOfStoreSymlink "${currentFolder}/agents";

    home.file.".claude/commands".source =
      config.lib.file.mkOutOfStoreSymlink "${currentFolder}/commands";

    # ~/.claude/skills is the repo folder itself, so the extra skills get linked into the repo.
    home.activation.claudeExtraSkills = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [[ ! -v DRY_RUN ]]; then
        wanted=(${lib.escapeShellArgs (builtins.attrNames extraSkills)})

        # If a link from the last activation is no longer wanted, remove it.
        if [[ -f ${stateFile} ]]; then
          while read -r name; do
            if [[ " ''${wanted[*]} " != *" $name "* && -L ${skillsFolder}/$name ]]; then
              rm ${skillsFolder}/"$name"
            fi
          done < ${stateFile}
        fi

        ${lib.concatStrings (lib.mapAttrsToList (name: path: ''
          # If a real folder already has this name, it is a repo skill. Leave it alone.
          if [[ -e ${skillsFolder}/${name} && ! -L ${skillsFolder}/${name} ]]; then
            errorEcho "claude extra skill ${name}: ${skillsFolder}/${name} exists and is not a link"
          else
            ln -sfnr ${lib.escapeShellArg path} ${skillsFolder}/${name}
          fi
        '')
        extraSkills)}

        mkdir -p "$(dirname ${stateFile})"
        printf '%s\n' "''${wanted[@]}" > ${stateFile}

        # Keep the links out of git status. The block in .git/info/exclude is local and never committed.
        if [[ -f ${gitExclude} ]]; then
          sed -i '/^${excludeBegin}$/,/^${excludeEnd}$/d' ${gitExclude}
          {
            echo '${excludeBegin}'
            for name in "''${wanted[@]}"; do echo "/${skillsRepoPath}/$name"; done
            echo '${excludeEnd}'
          } >> ${gitExclude}
        fi
      fi
    '';
  };
}
