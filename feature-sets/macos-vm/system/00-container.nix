# The dockurr/macos container: an Intel macOS 15 VM in QEMU. You install macOS by hand in the web console.
#
# All state lives in /var/lib/macos. Delete it to reinstall from scratch.
# ~/macshare is the 9p share. Its .setup folder holds setup.sh and the SSH keys for the first run.
{
  lib,
  pkgs,
  vars,
  ...
}: let
  stateDir = "/var/lib/macos";
  shareDir = "/home/${vars.username}/macshare";
  authorizedKeys = pkgs.writeText "macos-authorized-keys" (builtins.concatStringsSep "\n" vars.ssh-authorized-keys + "\n");
in {
  virtualisation.oci-containers = {
    backend = "docker";
    containers.macos = {
      image = "dockurr/macos:3.12";
      environment = {
        VERSION = "15";
        # Under host memory pressure, ballooning takes unused RAM back from macOS, down to 33% of RAM_SIZE.
        RAM_SIZE = "32G";
        BALLOONING = "Y";
        # With RAM_CHECK, a VM that starts while free RAM is short runs with a smaller RAM_SIZE until its next start.
        RAM_CHECK = "N";
        # macOS accepts only some core counts. 24 is the largest one below the 28 host threads.
        CPU_CORES = "24";
        DISK_SIZE = "192G";
        # NAT mode forwards all ports already. This keeps SSH working if dockurr falls back to user-mode networking.
        USER_PORTS = "22";
      };
      volumes = [
        "${stateDir}/storage:/storage"
        "${shareDir}:/shared"
      ];
      ports = [
        "127.0.0.1:8007:8006"
        # icewm-vnc in flake-local.nix holds 5900 on the host.
        "127.0.0.1:5901:5900/tcp"
        "127.0.0.1:2223:22"
      ];
      devices = ["/dev/kvm" "/dev/net/tun"];
      capabilities.NET_ADMIN = true;
      extraOptions = ["--stop-timeout=120"];
    };
  };

  systemd.services.docker-macos = {
    preStart = ''
      mkdir -p ${stateDir}/storage ${stateDir}/provision

      # If no provisioning key exists yet, generate one. macos-provision.service logs in with it.
      if [ ! -e ${stateDir}/provision/id_ed25519 ]; then
        ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -C macos-provision -f ${stateDir}/provision/id_ed25519
      fi

      # Put the first-run files into the share, where macOS reads them.
      install -d -o ${vars.username} -g users ${shareDir}/.setup
      install -o ${vars.username} -g users -m 0644 ${./setup/setup.sh} ${shareDir}/.setup/setup.sh
      cat ${authorizedKeys} ${stateDir}/provision/id_ed25519.pub > ${shareDir}/.setup/authorized_keys
      chown ${vars.username}:users ${shareDir}/.setup/authorized_keys
    '';
    # docker stop waits up to --stop-timeout for macOS to shut down. Leave room for the cleanup after it.
    serviceConfig.TimeoutStopSec = lib.mkForce 180;
  };

  systemd.tmpfiles.rules = [
    # QEMU serves the share as root, so files that macOS creates come out owned by root.
    "d ${shareDir} 0755 ${vars.username} users -"
  ];
}
