# Vars every host shares. Each hosts/<name>/vars.nix adds and overrides its own, and host is the folder name.
{...}: {
  flakeRoot = "/home/akelbsch/.nixos-config"; # Absolute path of this repo on every host
  username = "akelbsch";

  gitName = "aaron kelbsch";
  gitMail = "git@kelbsch.net";

  kbdLayout = "us";

  ssh-authorized-keys = []; # Public keys that may log in, if sshd or server is on
}
