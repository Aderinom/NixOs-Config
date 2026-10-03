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
    install -Dm644 CLAUDE.md $out/share/claude-box/CLAUDE.md
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
    description = "Run Claude Code in a Nix-based Docker sandbox with only the current directory mounted";
    longDescription = ''
      Wrapper that starts Claude Code inside a Nix-based container with $PWD
      bind-mounted at the same path. The image includes the usual agent tools
      and keeps everything outside that directory invisible to the agent.
      Requires a working docker daemon on the host.
    '';
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "claude-box";
  };
}
