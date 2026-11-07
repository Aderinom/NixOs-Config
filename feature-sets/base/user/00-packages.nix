{pkgs, ...}: {
  home.packages = with pkgs; [
    eza # ls replacement
    fd # find replacement
    jq # JSON processor
    file # Get File type
    gtrash # put deleted files in system trash
    ripgrep # grep replacement
    ripgrep-all
    p7zip # Seven zip
    unzip
    hexdump
    xxd # Hexdump - but prettier
    wget
    curl
    traceroute
    psmisc
    dialog
    tealdeer
    yazi
    tree
    nmap
    iftop
    inetutils
    openssl
    man-pages
    ncdu # disk space analyzer
    htop
    btop
  ];
}
