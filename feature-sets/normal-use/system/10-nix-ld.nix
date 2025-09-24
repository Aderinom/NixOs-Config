{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.nix-alien
  ];
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    openssl.dev
  ];
}
