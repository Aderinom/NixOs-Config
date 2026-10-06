# Installs the tools below in the Windows VM with winget, over SSH as the user dev.
#
# The service waits for SSH, so on the first install it runs about an hour after the container starts.
# If the tool list changes, nixos-rebuild switch restarts the service. To run it again by hand:
#   systemctl restart windows-provision
# Removing a tool from the list does not uninstall it. winget skips tools that are already installed and does not upgrade them.
{
  lib,
  pkgs,
  ...
}: let
  stateDir = "/var/lib/windows";

  # Each entry is a winget package id. `override` replaces the installer arguments.
  # `path` goes into the machine PATH, for installers that do not add themselves.
  # The order matters: rustup needs the MSVC linker and the Windows SDK from the Build Tools.
  tools = [
    {
      id = "Microsoft.VisualStudio.BuildTools";
      override = "--wait --quiet --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended";
    }
    {id = "Rustlang.Rustup";}
    {id = "Git.Git";}
    # aws-lc-sys, the default crypto backend of rustls
    {
      id = "NASM.NASM";
      path = "C:\\Program Files\\NASM";
    }
    # openssl-sys with the vendored feature
    {id = "StrawberryPerl.StrawberryPerl";}
    # libclang for bindgen
    {
      id = "LLVM.LLVM";
      path = "C:\\Program Files\\LLVM\\bin";
    }
    {id = "Kitware.CMake";}
    {id = "Microsoft.PowerShell";}
    {id = "Python.Python.3.14";}
  ];

  provisionScript = pkgs.writeText "windows-provision.ps1" ''
    $ErrorActionPreference = 'Stop'

    # winget appears only after App Installer registers for the user, some minutes after the first logon.
    $deadline = (Get-Date).AddMinutes(30)
    while (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
      if ((Get-Date) -gt $deadline) { throw 'winget not found after 30 minutes' }
      Start-Sleep -Seconds 30
    }

    # 0x8A150061: already installed. 0x8A150109: installed, needs a restart to finish.
    $ok = @(0, -1978335135, -1978334967)
    $tools = '${lib.replaceStrings ["'"] ["''"] (builtins.toJSON tools)}' | ConvertFrom-Json
    $failed = @()
    foreach ($tool in $tools) {
      $wingetArgs = @('install', '--exact', '--id', $tool.id, '--source', 'winget', '--silent', '--no-upgrade',
        '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
      if ($tool.override) { $wingetArgs += @('--override', $tool.override) }
      & winget @wingetArgs
      if ($ok -notcontains $LASTEXITCODE) {
        Write-Host ('{0} failed with 0x{1:X8}' -f $tool.id, $LASTEXITCODE)
        $failed += $tool.id
      }
      if ($tool.path) {
        $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
        if (($machinePath -split ';') -notcontains $tool.path) {
          [Environment]::SetEnvironmentVariable('Path', $machinePath.TrimEnd(';') + ';' + $tool.path, 'Machine')
        }
      }
    }
    if ($failed) { throw ('failed: ' + ($failed -join ', ')) }
  '';

  ssh = "${pkgs.openssh}/bin/ssh";
  sshOpts = lib.concatStringsSep " " [
    "-i ${stateDir}/provision/id_ed25519"
    "-o UserKnownHostsFile=${stateDir}/provision/known_hosts"
    # The host key is new after each reinstall, and the VM is only reachable from localhost.
    "-o StrictHostKeyChecking=accept-new"
    "-o BatchMode=yes"
    "-o ConnectTimeout=10"
  ];
in {
  systemd.services.windows-provision = {
    description = "Install the dev tools in the Windows VM";
    requires = ["docker-windows.service"];
    after = ["docker-windows.service"];
    partOf = ["docker-windows.service"];
    # multi-user.target makes the first switch start it. docker-windows.service makes windows-start start it.
    wantedBy = ["multi-user.target" "docker-windows.service"];
    # A simple service lets nixos-rebuild finish while this waits for the first install.
    # RemainAfterExit keeps it active after success, so a changed tool list restarts it.
    serviceConfig = {
      Type = "simple";
      RemainAfterExit = true;
    };
    script = ''
      until ${ssh} -p 2222 ${sshOpts} dev@127.0.0.1 exit 2>/dev/null; do
        sleep 30
      done
      ${pkgs.openssh}/bin/scp -P 2222 ${sshOpts} ${provisionScript} dev@127.0.0.1:provision.ps1
      ${ssh} -p 2222 ${sshOpts} dev@127.0.0.1 powershell -NoProfile -ExecutionPolicy Bypass -File provision.ps1
    '';
  };
}
