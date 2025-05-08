{inputs, ...}: {
  # Allow usage of custom packages
  additions = final: _prev: import ../pkgs final.pkgs;

  modifications = final: prev: {
    # Register all overlays here
    displaylink = import ./displaylink/displaylink.nix {inherit final prev;};
  };

  # Allows unstable packages to be accessed with 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
