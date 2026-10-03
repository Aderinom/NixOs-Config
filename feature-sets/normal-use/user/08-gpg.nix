{pkgs, ...}: {
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
    extraConfig = ''
      default-cache-ttl 600
      max-cache-ttl 7200
    '';
  };

  home.packages = with pkgs; [
    pinentry-curses
    gnupg
  ];

  home.file.".gnupg/common.conf".text = ''
    use-keyboxd
  '';
}
