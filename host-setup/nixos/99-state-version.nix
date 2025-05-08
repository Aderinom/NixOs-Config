{...}: {
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

  system.stateVersion = "23.11";
}
