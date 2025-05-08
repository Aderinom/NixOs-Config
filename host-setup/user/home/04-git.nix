{
  gitMail,
  gitName,
  ...
}: {
  programs.git.enable = true;
  programs.git.userEmail = gitMail;
  programs.git.userName = gitName;
  programs.git.lfs.enable = true;

  programs.git.extraConfig = {
    commit.gpgsign = true;
    user.signingkey = "~/.ssh/sign-key.pub";
    gpg.format = "ssh";
    push.autoSetupRemote = true;
  };
}
