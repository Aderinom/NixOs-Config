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
    push.autoSetupRemote = true;
  };
}
