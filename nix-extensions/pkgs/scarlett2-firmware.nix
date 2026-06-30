{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  ...
}:
stdenvNoCC.mkDerivation rec {
  pname = "scarlett2-firmware";
  version = "1.1";

  src = fetchFromGitHub {
    owner = "geoffreybennett";
    repo = "scarlett2-firmware";
    rev = version;
    hash = "sha256-IrhLFBXymiVGYenYP+v/IRWJqMIakWWQNaorHzPv/LM=";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/lib/firmware/scarlett2
    cp firmware/* $out/lib/firmware/scarlett2/
  '';

  meta = with lib; {
    description = "Firmware for Focusrite Scarlett, Clarett USB, Clarett+, and Vocaster interfaces";
    homepage = "https://github.com/geoffreybennett/scarlett2-firmware";
    license = licenses.unfreeRedistributable;
    platforms = platforms.linux;
  };
}
