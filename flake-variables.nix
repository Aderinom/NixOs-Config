{...}: {
  flakeRoot = "/home/akelbsch/.nixos-config";
  username = "akelbsch";

  gitName = "Aaron Kelbsch";
  gitMail = "git@kelbsch.net";

  host = "durr-station";
  kbdLayout = "de,us";


  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  # When do I update stateVersion
  # Keep stateVersion to the version you originally installed.[1]

  # The system.stateVersion option is described as such:

  # Every once in a while, a new NixOS release may change configuration defaults in a way incompatible with stateful
  # data. For instance, if the default version of PostgreSQL changes, the new version will probably be
  # unable to read your existing databases. To prevent such breakage, you can set the value of this option to the
  # NixOS release with which you want to be compatible.
  # The effect is that NixOS will option defaults corresponding to the specified release
  # (such as using an older version of PostgreSQL).

  # Frequent answers:

  # stateVersion has nothing to do with the current version of the system[2]
  # Do NOT change the stateVersion in the configuration; [it] tells nixos what version your state is; changing it will break the things [it is] meant to fix.[3]
  # When can I update stateVersion?

  # When:

  # You have read all release notes starting from your stateVersion.
  # You have verified all instances of stateVersion in the code in <nixpkgs/nixos>.
  # You have made all manual interventions as required by the changes previously inventoried.
  nix-state-version = "23.11";


  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home-mgr-state-version = "24.11";
}
