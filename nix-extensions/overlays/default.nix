{inputs, ...}: {
  # Allow usage of custom packages
  additions = final: _prev: import ../pkgs final.pkgs;

  modifications = final: prev: {
    # Register all overlays here
    displaylink = import ./displaylink/displaylink.nix {inherit final prev;};
  };

  # Replaces inputs.spt-linux-guide.overlays.default. That overlay reads the
  # deprecated `pkgs.system` and prints an eval warning.
  spt-packages = _final: prev: let
    sptPkgs = inputs.spt-linux-guide.packages.${prev.stdenv.hostPlatform.system};
  in {
    inherit (sptPkgs) spt-additions spt-server spt-launcher;
  };

  # Allows unstable packages to be accessed with 'pkgs.unstable'
  unstable-packages = _final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (prev.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };
}
