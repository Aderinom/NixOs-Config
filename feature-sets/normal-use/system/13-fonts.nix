{pkgs, ...}: {
  fonts.packages = with pkgs;
    [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji
      font-awesome
      meslo-lgs-nf
      corefonts
    ]
    ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
}
