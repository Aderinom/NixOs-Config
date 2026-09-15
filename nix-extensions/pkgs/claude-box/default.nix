{
  lib,
  stdenvNoCC,
  makeWrapper,
  bash,
  coreutils,
  gnutar,
}:
stdenvNoCC.mkDerivation {
  pname = "claude-box";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [makeWrapper];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # The build context the script feeds to `docker build`.
    install -Dm644 Dockerfile $out/share/claude-box/Dockerfile
    install -Dm755 claude-box.sh $out/bin/claude-box

    substituteInPlace $out/bin/claude-box \
      --replace-fail '@context@' "$out/share/claude-box"

    # docker is deliberately left to the ambient PATH so the CLI matches the
    # daemon the host actually runs; the script errors out nicely without it.
    wrapProgram $out/bin/claude-box \
      --prefix PATH : ${lib.makeBinPath [bash coreutils gnutar]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Run Claude Code in a Docker sandbox with only the current directory mounted";
    longDescription = ''
      Wrapper that starts Claude Code inside a container with $PWD bind-mounted
      at the same path. Everything outside that directory is invisible to the
      agent, so permission prompts are bypassed by default. Requires a working
      docker daemon on the host.
    '';
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "claude-box";
  };
}
