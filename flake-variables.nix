{...}: {
  imports = [
    (abort "You need to set up the flake Variables and delete the first few lines, containing this error to install this flake!")
  ];

  flakeRoot = "/home/user/.nixos-config"; # Absolute Path of the flake - I personally like /home/<user>/.nixos-config
  username = "user"; # Your desired user name

  gitName = "git user"; # Desired git user name
  gitMail = "git@git.git"; # Desired git mail

  host = "host"; # Desired hostname
  kbdLayout = "de,us"; # Desired Keyboard Layout

  nix-state-version = "xx.xx"; # Nix Version of initial nixos installation see [1]
  home-mgr-state-version = "xx.xx"; # Home Manager Version of initial install see [2]

  uses-nvidia-gpu = false;

  # Add the feature sets you want to use here.
  enabled-features = [
    ./feature-sets/desktop/hyprland
    ./feature-sets/normal-use
    #./feature-sets/personal-use
    #./feature-sets/professional-use
  ];
}
/**

[1] State Version <https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion>


  When do I update stateVersion
  Keep stateVersion to the version you originally installed.[1]

  The system.stateVersion option is described as such:

  Every once in a while, a new NixOS release may change configuration defaults in a way incompatible with stateful
  data. For instance, if the default version of PostgreSQL changes, the new version will probably be
  unable to read your existing databases. To prevent such breakage, you can set the value of this option to the
  NixOS release with which you want to be compatible.
  The effect is that NixOS will option defaults corresponding to the specified release
  (such as using an older version of PostgreSQL).

  Frequent answers:

  stateVersion has nothing to do with the current version of the system[2]
  Do NOT change the stateVersion in the configuration; [it] tells nixos what version your state is; changing it will break the things [it is] meant to fix.[3]
  When can I update stateVersion?

  When:

  You have read all release notes starting from your stateVersion.
  You have verified all instances of stateVersion in the code in <nixpkgs/nixos>.
  You have made all manual interventions as required by the changes previously inventoried.


[2] Home Manager State Version

  This value determines the Home Manager release that your configuration is
  compatible with. This helps avoid breakage when a new Home Manager release
  introduces backwards incompatible changes.

  You should not change this value, even if you update Home Manager. If you do
  want to update the value, then make sure to first check the Home Manager
  release notes.
*/

