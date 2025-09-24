{
  description = "Aaron's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nur.url = "github:nix-community/NUR";

    solaar = {
      url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz"; # For latest stable version
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server.url = "github:nix-community/nixos-vscode-server";

    nix-alien.url = "github:thiagokokada/nix-alien"; # Unpatched binary runner
    nix-init.url = "github:nix-community/nix-init"; # Auto PKG generator
    nix-index-database.url = "github:nix-community/nix-index-database"; # Fast package search
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
          ./flake-nix-config.nix
          ./hosts/laptop
        ];
      };

      desktop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs vars;};
        modules = [
          ./flake-nix-config.nix
          ./hosts/desktop
        ];
      };

      vm = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs vars;};
        modules = [
          inputs.nix-index-database.nixosModules.nix-index
          ./flake-nix-config.nix
          ./hosts/vm
        ];
      };
    };
  };
}
