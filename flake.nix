{
  description = "Aaron's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nur.url = "github:nix-community/NUR";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (self) outputs;
    vars = import ./flake-variables.nix {};
    # Define supported systems
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    # Generate attributes for all systems
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra); # Set formatter

    my = {
      pkgs = forAllSystems (system: import ./nix-extensions/pkgs nixpkgs.legacyPackages.${system}); # Import custom Packages
      overlays = import ./nix-extensions/overlays {inherit inputs;}; # Import overlays
      modules = import ./nix-extensions/modules; # Nix Os Modules to import
    };

    vars = vars;

    nixosConfigurations = {
      laptop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs vars;};
        modules = [
          inputs.nix-index-database.nixosModules.nix-index
          ./hardware-configuration.nix
          ./hardware-extra-configuration.nix
          ./flake-nix-config.nix
          ./flake-system.nix
          ./flake-home-manager.nix
          ./hosts/laptop
        ];
      };

      vm = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs vars;};
        modules = [
          inputs.nix-index-database.nixosModules.nix-index
          ./hardware-configuration.nix
          ./flake-nix-config.nix
          ./flake-system.nix
          ./flake-home-manager.nix
          ./hosts/vm
        ];
      };
    };
  };
}
