{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    openssl.dev
    pkg-config
    # #Rust
    # rustup
  ];
}
