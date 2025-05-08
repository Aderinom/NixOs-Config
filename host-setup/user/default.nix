{
  pkgs,
  inputs,
  outputs,
  username,
  host,
  gitName,
  gitMail,
  flakeRoot,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager.backupFileExtension = "hm-backup";
  home-manager = {
    useUserPackages = true; # Install packages to /etc/profiles instead of  $HOME/.nix-profile - Might become standard
    useGlobalPkgs = true; # Use nixpkgs from system

    extraSpecialArgs = {inherit inputs username host gitName gitMail flakeRoot;};

    users.${username} = {
      imports = [
        outputs.my.modules.home-manager
        ./home
        ../desktop/hyprland/home
      ];
      home.username = "${username}";
      home.homeDirectory = "/home/${username}";

      programs.home-manager.enable = true;
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [
      "networkmanager"
      "wheel"
      "plugdev"
    ];
    shell = pkgs.fish;
  };

  nix.settings.allowed-users = ["${username}"];
}
