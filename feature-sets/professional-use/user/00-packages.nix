{pkgs, ...}: {
  home.packages = with pkgs; [
    slack
    pass
    gh
    protobuf
  ];
}
