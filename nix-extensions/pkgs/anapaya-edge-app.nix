{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  wrapGAppsHook3,
  systemd,
  at-spi2-atk,
  ayatana-ido,
  cairo,
  fontconfig,
  gdk-pixbuf,
  glib,
  gtk3,
  harfbuzz,
  libayatana-appindicator,
  libayatana-indicator,
  libdbusmenu,
  libdbusmenu-gtk3,
  libepoxy,
  libgcc,
  libnotify,
  pango,
  zlib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "anapaya-edge-app";
  version = "0.9.2";

  src = fetchurl {
    url = "https://storage.googleapis.com/edge_app_releases/releases/v${finalAttrs.version}/linux/anapaya-edge-app-v${finalAttrs.version}.deb";
    hash = "sha256-iRWhoXtANr4mV2H0t7OuHOfLyVQXtCap5ZEwqx68THs=";
  };

  nativeBuildInputs = [autoPatchelfHook dpkg makeWrapper wrapGAppsHook3];

  buildInputs = [
    at-spi2-atk
    ayatana-ido
    cairo
    fontconfig.lib
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    libayatana-appindicator
    libayatana-indicator
    libdbusmenu
    libdbusmenu-gtk3
    libepoxy
    libgcc.lib
    libnotify
    pango
    zlib
  ];

  # libdartjni.so is linked against a JVM that only exists when the Dart
  # runtime is embedded in a Java host. Nothing in this app loads it.
  autoPatchelfIgnoreMissingDeps = ["libjvm.so"];

  # flutter_rust_bridge dlopen()s librust_lib_edge_app.so by bare name, so
  # it is resolved against the runpath of libflutter_linux_gtk.so, which
  # shipped as $ORIGIN and gets overwritten by autoPatchelfHook.
  appendRunpaths = ["${placeholder "out"}/share/anapaya-edge-app/lib"];

  # Unpacks ./opt, ./usr and ./etc into the build directory; there is no
  # single source root to descend into.
  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  # The wrappers are created by hand below so the GTK environment lands on
  # them; let wrapGAppsHook3 only collect the arguments.
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    # edge_app has RUNPATH $ORIGIN/lib, so the binary has to stay next to
    # the lib/ and data/ directories it shipped with.
    mkdir -p $out/share
    cp -r opt/anapaya/edge-app $out/share/anapaya-edge-app
    cp -r usr/share/icons $out/share/

    # squiche statically links BoringSSL, whose compiled-in default trust
    # roots are /etc/ssl/cert.pem (absent on NixOS) and the hashed-symlink
    # dir /etc/ssl/certs (NixOS ships only bundles there, no <hash>.0
    # links). Both lookups come up empty, so every HSD handshake dies with
    # CERTIFICATE_VERIFY_FAILED. Point it at the real bundle instead.

    makeWrapper $out/share/anapaya-edge-app/edge_app $out/bin/edge_app \
      --set-default SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt \
      "''${gappsWrapperArgs[@]}"

    ln -s edge_app $out/bin/anapaya-edge-app

    makeWrapper $out/share/anapaya-edge-app/edge_app_daemon $out/bin/edge_app_daemon \
      --set-default SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt

    install -Dm444 usr/share/applications/anapaya-edge-app.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/anapaya-edge-app.desktop \
      --replace-fail /opt/anapaya/edge-app/edge_app $out/bin/edge_app

    # The helper runs `pkexec systemctl ...`, and pkexec resolves the
    # command against a Debian-shaped PATH. Pin it to a real one.
    substituteInPlace $out/share/anapaya-edge-app/helpers/anapaya-daemon-ctl \
      --replace-fail "pkexec systemctl" "pkexec ${lib.getExe' systemd "systemctl"}"

    runHook postInstall
  '';

  # The polkit rule below has to authorise the exact binary the helper
  # invokes, so publish it rather than letting the two drift apart.
  passthru.daemonCtlSystemctl = lib.getExe' systemd "systemctl";

  meta = {
    description = "Anapaya Edge App";
    homepage = "https://www.anapaya.net/";
    license = lib.licenses.unfree;
    mainProgram = "edge_app";
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
})
