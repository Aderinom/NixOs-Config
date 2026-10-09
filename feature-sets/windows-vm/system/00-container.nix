# The dockurr/windows container: a Windows 11 VM in QEMU, installed unattended on first start.
#
# All state lives in /var/lib/windows. Delete it to reinstall from scratch.
# Windows reads USERNAME, PASSWORD, VERSION and the OEM folder only during that first install.
{
  lib,
  pkgs,
  vars,
  ...
}: let
  stateDir = "/var/lib/windows";
  shareDir = "/home/${vars.username}/winshare";
  authorizedKeys = pkgs.writeText "windows-authorized-keys" (builtins.concatStringsSep "\n" vars.ssh-authorized-keys + "\n");
in {
  virtualisation.oci-containers = {
    backend = "docker";
    containers.windows = {
      image = "dockurr/windows:6.05";
      environment = {
        VERSION = "11";
        # Under host memory pressure, ballooning takes unused RAM back from Windows, down to 33% of RAM_SIZE.
        RAM_SIZE = "32G";
        BALLOONING = "Y";
        # With RAM_CHECK, a VM that starts while free RAM is short runs with a smaller RAM_SIZE until its next start.
        RAM_CHECK = "N";
        CPU_CORES = "28";
        DISK_SIZE = "128G";
        USERNAME = "dev";
        # NAT mode forwards all ports already. This keeps SSH working if dockurr falls back to user-mode networking.
        USER_PORTS = "22";
      };
      environmentFiles = ["${stateDir}/password.env"];
      volumes = [
        "${stateDir}/storage:/storage"
        "${stateDir}/oem:/oem"
        "${shareDir}:/shared"
      ];
      ports = [
        "127.0.0.1:8006:8006"
        "127.0.0.1:3389:3389/tcp"
        "127.0.0.1:3389:3389/udp"
        "127.0.0.1:2222:22"
      ];
      devices = ["/dev/kvm" "/dev/net/tun"];
      capabilities.NET_ADMIN = true;
      extraOptions = ["--stop-timeout=120"];
    };
  };

  systemd.services.docker-windows = {
    preStart = ''
      mkdir -p ${stateDir}/storage ${stateDir}/oem ${stateDir}/provision

      # If no password exists yet, generate one. Read it with: sudo cat ${stateDir}/password.env
      if [ ! -e ${stateDir}/password.env ]; then
        (umask 077; echo "PASSWORD=$(${pkgs.openssl}/bin/openssl rand -hex 12)" > ${stateDir}/password.env)
      fi

      # If no provisioning key exists yet, generate one. windows-provision.service logs in with it.
      if [ ! -e ${stateDir}/provision/id_ed25519 ]; then
        ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -C windows-provision -f ${stateDir}/provision/id_ed25519
      fi

      cp --no-preserve=mode ${./oem/install.bat} ${stateDir}/oem/install.bat
      cat ${authorizedKeys} ${stateDir}/provision/id_ed25519.pub > ${stateDir}/oem/authorized_keys
    '';
    # docker stop waits up to --stop-timeout for Windows to shut down. Leave room for the cleanup after it.
    serviceConfig.TimeoutStopSec = lib.mkForce 180;
  };

  systemd.tmpfiles.rules = [
    # Samba in the container writes as the guest account nobody. Files from Windows come out owned by nobody.
    "d ${shareDir} 2777 ${vars.username} users -"
  ];
}
