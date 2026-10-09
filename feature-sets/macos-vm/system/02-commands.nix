# Host commands for the macOS VM: macos-ssh, macos-start, macos-stop.
{
  pkgs,
  vars,
  ...
}: {
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "macos-ssh";
      runtimeInputs = [pkgs.openssh];
      # macos-provision.service records the host key for [127.0.0.1]:2223 on its first login. A reinstall deletes the file with it.
      text = ''
        exec ssh -p 2223 \
          -o UserKnownHostsFile=/var/lib/macos/provision/known_hosts \
          -o StrictHostKeyChecking=yes \
          dev@127.0.0.1 "$@"
      '';
    })
    (pkgs.writeShellApplication {
      name = "macos-start";
      text = "systemctl start docker-macos.service";
    })
    (pkgs.writeShellApplication {
      name = "macos-stop";
      # Blocks until macOS has shut down, up to 2 minutes.
      text = "systemctl stop docker-macos.service";
    })
  ];

  # Lets the user start and stop the VM without sudo.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          ["docker-macos.service", "macos-provision.service"].indexOf(action.lookup("unit")) >= 0 &&
          subject.user == "${vars.username}") {
        return polkit.Result.YES;
      }
    });
  '';
}
