{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    bazelisk
    ## Add a wrapper script so bazel can be called directly, and it will use bazelisk to find the correct version of bazel to run.
    (pkgs.writeShellScriptBin "bazel" ''
      bazelisk "$@"
    '')
  ];

  system.activationScripts = {
    # Make /bin/bash available
    binbash = {
      # Run after /dev has been mounted
      deps = ["specialfs"];
      text = ''
        ln -s /run/current-system/sw/bin/bash /bin/bash
      '';
    };
    # Bazel requires FHS, but I don't want to use a full FHS environment. Instead, just link the necessary tools into /bin and /usr/bin.
    bazelBin = ''
      mkdir -p /bin
      for f in ${pkgs.buildEnv {
        name = "gnu-bin";
        paths = with pkgs; [
          coreutils
          findutils
          gnused
          gnugrep
          gawk
          diffutils
          patch
          which
          gnutar
          gzip
          bzip2
          xz
          rsync
          binutils
          python3
        ];
        pathsToLink = ["/bin"];
      }}/bin/*; do
        ln -sf "$f" /bin/$(basename "$f")
      done
    '';

    bazelUsrBin = ''
      mkdir -p /usr/bin
      for f in ${pkgs.buildEnv {
        name = "gnu-bin";
        paths = with pkgs; [
          python3
        ];
        pathsToLink = ["/bin"];
      }}/bin/*; do
        ln -sf "$f" /usr/bin/$(basename "$f")
      done
    '';
  };
}
