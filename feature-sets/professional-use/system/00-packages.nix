{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    mktemp
    bazelisk
    python3
    go
    ansible
    vagrant
  ];
}
