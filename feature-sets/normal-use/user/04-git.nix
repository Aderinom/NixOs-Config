{vars, ...}: {
  programs.git.enable = true;
  programs.git.userEmail = vars.gitMail;
  programs.git.userName = vars.gitName;
  programs.git.lfs.enable = true;
  programs.git.delta.enable = true;

  programs.git.extraConfig = {
    commit.gpgsign = true;
    user.signingkey = "~/.ssh/sign-key.pub";
    gpg.format = "ssh";

    core.editor = "code";
    core.ignorecase = false;

    merge.conflictStyle = "zdiff3";

    init.defaultBranch = "main";

    push.autoSetupRemote = true;
    pull.rebase = true;

    fetch.prune = true;

    gc.autoDetach = true;
    gc.writeCommitGraph = true;

    rebase.autosquash = true;
    rebase.autostash = true;
    rebase.updateRefs = true;

    # Try to rememboer how to resolve certain conflicts
    rerere.enabled = true;

    # Eagerly check objects for integrity
    transfer.fsckObjects = true;
    fetch.fsckObjects = true;
    receive.fsckObjects = true;
  };
}
