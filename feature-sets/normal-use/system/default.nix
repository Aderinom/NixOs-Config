{...}: {
  imports = [
    ./chromium
    ./00-packages.nix
    ./01-kernel.nix
    ./04-network.nix
    ./05-systemd.nix
    ./07-audio.nix
    ./12-headsetcontrol.nix
    ./14-virtualization.nix
    ./17-printer.nix
    ./18-scanner.nix
    ./19-logitech.nix
    ./21-disk-tuning.nix
    ./22-ddcutil.nix
    ./98-programs.nix
  ];

  myConfig.features.base.enable = true;
  myConfig.features.graphical-session.enable = true;
}
