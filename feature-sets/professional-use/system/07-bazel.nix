{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    bazelisk
    ## Add a wrapper script so bazel can be called directly, and it will use bazelisk to find the correct version of bazel to run.
    (pkgs.writeShellScriptBin "bazel" ''
      bazelisk "$@"
    '')
  ];
}
