# Host commands for the Windows VM: windows-ssh, windows-start, windows-stop.
{
  pkgs,
  vars,
  ...
}: {
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "windows-ssh";
      runtimeInputs = [pkgs.openssh];
      # windows-provision.service records the host key for [127.0.0.1]:2222 on its first login. A reinstall deletes the file with it.
      text = ''
        exec ssh -p 2222 \
          -o UserKnownHostsFile=/var/lib/windows/provision/known_hosts \
          -o StrictHostKeyChecking=yes \
          dev@127.0.0.1 "$@"
      '';
    })
    (pkgs.writeShellApplication {
      name = "windows-start";
      text = "systemctl start docker-windows.service";
    })
    (pkgs.writeShellApplication {
      name = "windows-stop";
      # Blocks until Windows has shut down, up to 2 minutes.
      text = "systemctl stop docker-windows.service";
    })
  ];

  # Lets the user start and stop the VM without sudo.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          ["docker-windows.service", "windows-provision.service"].indexOf(action.lookup("unit")) >= 0 &&
          subject.user == "${vars.username}") {
        return polkit.Result.YES;
      }
    });
  '';
}
