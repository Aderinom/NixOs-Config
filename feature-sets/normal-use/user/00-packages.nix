{pkgs, ...}: {
  home.packages = with pkgs; [
    # Simple Cli Commands
    wl-clipboard # clipboard utils for wayland (wl-copy, wl-paste)
    xdg-utils
    gh # GitHub CLI

    # Niche Cli Commands
    playerctl # controller for media players
    ffmpeg
    yt-dlp-light
    hyperfine #CLI Benchmarking tool
    presenterm #CLI Slideshow tool

    # Other

    # CLI TUIs
    ani-cli
    binsider # ELF analyzer TUI
    bitwise # cli tool for bit / hex manipulation
    docfd # TUI multiline fuzzy document finder
    programmer-calculator #pcalc
    tdf # cli pdf viewer
    wavemon # monitoring for wireless network devices

    # CLI Toys
    imv # image viewer
    mpv # video player
    onefetch # Pretty fetch for git repos
    ## Even more toyj
    cbonsai # terminal screensaver
    cmatrix # terminal screensaver
    pipes # terminal screensaver
    tty-clock # cli clock
    lolcat

    # Libs
    libappindicator
    libnotify
    poweralertd

    # GUI Programs
    dbeaver-bin
    remmina
    drawio
    krita
    onlyoffice-desktopeditors
    spotify

    ## GUI Apps
    audacity
    nix-prefetch-github
    soundwireserver
    vlc
    obsidian

    ## Programming
    # Typescript
    unstable.bun
    nodejs_latest
    pnpm

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
