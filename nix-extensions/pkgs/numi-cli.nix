{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  pkgs,
  ...
}:
stdenv.mkDerivation rec {
  pname = "numi-cli";
  version = "0.13.0";

  src = fetchurl {
    url = "https://github.com/nikolaeu/numi/releases/download/cli-v${version}/numi-cli-v${version}-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-W/y3ncNYuoXg5J8qR78+yCXNfzPxGFkEDl88uX8qv68="; # Replace this with the actual hash after the first build attempt
  };

  nativeBuildInputs = [autoPatchelfHook];

  buildInputs = [
    pkgs.openssl
    pkgs.gcc-unwrapped
  ];

  unpackPhase = ''
    tar xzf $src
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp numi-cli $out/bin/
    chmod +x $out/bin/numi-cli
  '';

  meta = with lib; {
    description = "Numi CLI - powerful calculator and converter";
    homepage = "https://github.com/nikolaeu/numi";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [klden];
  };
}
