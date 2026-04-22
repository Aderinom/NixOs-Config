{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = [
    pkgs.nix-alien
  ];

  system.activationScripts = {
    # Make /bin/bash available
    binbash = {
      # Run after /dev has been mounted
      deps = ["specialfs"];
      text = ''
        ln -s /run/current-system/sw/bin/bash /bin/bash
      '';
    };
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    inputs.nix-init.packages.${pkgs.system}.nix-init
    openssl.dev
  ];
}
