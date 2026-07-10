{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = [
    pkgs.nix-alien
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    inputs.nix-init.packages.${pkgs.system}.nix-init
    openssl.dev
  ];
}
