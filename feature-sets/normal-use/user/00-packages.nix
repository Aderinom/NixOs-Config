{pkgs, ...}: {
  home.packages = with pkgs; [
    # Simple Cli Commands
    eza # ls replacement
    fd # find replacement
    jq # JSON processor
    file # Get File type
    wl-clipboard # clipboard utils for wayland (wl-copy, wl-paste)
    gtrash # put deleted files in system trash
    ripgrep # grep replacement
    p7zip # Seven zip
    unzip
    hexdump
    xxd # Hexdump - but prettier
    wget
    curl
    xdg-utils
    traceroute
    psmisc
    dialog
    tealdeer
    yazi
    ripgrep
    ripgrep-all

    # Niche Cli Commands
    pamixer # pulseaudio command line mixer
    playerctl # controller for media players
    ffmpeg
    yt-dlp-light
    openssl
    hyperfine #CLI Benchmarking tool
    presenterm #CLI Slideshow tool

    # Other
    man-pages

    # CLI TUIs
    ani-cli
    binsider # ELF analyzer TUI
    bitwise # cli tool for bit / hex manipulation
    docfd # TUI multiline fuzzy document finder
    ncdu # disk space analyzer
    htop
    btop
    programmer-calculator #pcalc
    tdf # cli pdf viewer
    wavemon # monitoring for wireless network devices
    yazi

    # CLI Toys
    imv # image viewer
    mpv # video player
    onefetch # Pretty fetch for git repos
    ## Even more toyj
    cbonsai # terminal screensaver
    cmatrix # terminal screensaver
    pipes # terminal screensaver
    tty-clock # cli clock

    # Libs
    libappindicator
    libnotify
    poweralertd

    # GUI Programms
    dbeaver-bin
    remmina
    drawio
    krita
    onlyoffice-bin
    spotify

    ## GUI Apps
    chromium
    audacity
    nix-prefetch-github
    soundwireserver
    vlc

    ## Programming
    # Typescript
    unstable.bun
    nodejs_latest
    corepack_latest
    pnpm_10

    #Rust
    rustup

    # C / C++
    musl
    gcc
    gdb
    cmake
    gnumake
    pkg-config

    # Python
    python3
    python312Packages.ipython

    # Audio
    easyeffects
  ];
}
