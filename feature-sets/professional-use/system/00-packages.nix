{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    mktemp
    python3
    go
    gopls
    ansible
    vagrant
  ];
}
