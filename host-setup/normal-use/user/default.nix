{
  pkgs,
  inputs,
  outputs,
  vars,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useUserPackages = true; # Install packages to /etc/profiles instead of  $HOME/.nix-profile - Might become standard
    useGlobalPkgs = true; # Use nixpkgs from system
    backupFileExtension = "hm-backup";

    extraSpecialArgs = {inherit inputs vars;};

    users.${vars.username} = {
      programs.home-manager.enable = true;
      
      home.stateVersion = vars.home-mgr-state-version;

      home.username = "${vars.username}";
      home.homeDirectory = "/home/${vars.username}";

      imports = [
        outputs.my.modules.home-manager
        ./home
        ../desktop/hyprland/home
      ];
    };
  };

  users.users.${vars.username} = {
    isNormalUser = true;
    description = "${vars.username}";
    extraGroups = [
      "networkmanager"
      "wheel"
      "plugdev"
    ];
    shell = pkgs.fish;
  };

  nix.settings.allowed-users = ["${vars.username}"];
}
