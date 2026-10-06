---
name: windows-vm
description: Run commands, copy files, and build code in the local Windows 11 VM over SSH. Use when a task needs Windows, for example a Windows or MSVC build, a Windows test, or a check of Windows behavior.
---

# Windows VM

A Windows 11 VM runs in the Docker container `windows`. The NixOS feature set
`~/.nixos-config/feature-sets/windows-vm` defines it. That folder is the source
of truth for ports, users, and the tool list.

## Check first

Run `command -v windows-ssh`. If it finds nothing, the feature set is off.
Stop and tell the user.

If `windows-ssh exit` fails, check the state:

```sh
systemctl status docker-windows windows-provision --no-pager
journalctl -u docker-windows -n 30 --no-pager
```

- If `docker-windows` is inactive, the VM is off. Ask the user before you run
  `windows-start`.
- If the journal shows a download or the install, Windows is not ready yet.
  The first install takes about an hour. The user can watch it at
  http://127.0.0.1:8006.
- If `windows-ssh` fails with `Host key verification failed`, provisioning
  has not logged in yet. Check `journalctl -u windows-provision`.

## Run commands

`windows-ssh <command>` runs the command as the admin user `dev` and returns
its exit code. The remote shell is `cmd.exe`, not a POSIX shell.

- Pass the remote command as one single-quoted string. Bash then leaves it
  alone, and only `cmd.exe` parses it.
- For PowerShell, call it explicitly:
  `windows-ssh 'powershell -NoProfile -Command "Get-ChildItem C:\Users\dev"'`
- If a script needs more than one line, copy a `.ps1` file over and run it
  with `-File`. Inline quoting through three parsers breaks fast.
- Use `cd /d` to change the drive and folder in `cmd.exe`.

## Copy files

Use `scp` with the same host key file as `windows-ssh`:

```sh
scp -P 2222 -o UserKnownHostsFile=/var/lib/windows/provision/known_hosts \
  -o StrictHostKeyChecking=yes -r ./project dev@127.0.0.1:src/project
```

Remote paths without a drive letter start in `C:\Users\dev`. Swap source and
destination to copy back.

`~/winshare` on the host is `Z:\` in the desktop session. SSH sessions do not
get that drive. Do not build from the share: SMB is slow and locks files.

## Build

- The tool list in `system/01-provision.nix` of the feature set says what is
  installed. If a tool is missing, tell the user to add it there. Do not
  install it by hand with winget.
- `cargo` finds the MSVC linker by itself. Do not run `vcvars`.
- A tool installed during this session appears on `PATH` only in a new SSH
  session.

Example:

```sh
windows-ssh 'cd /d C:\Users\dev\src\project && cargo build --release'
```

## Ask the user first

- before `windows-start` or `windows-stop`;
- before anything that deletes or changes `/var/lib/windows`;
- before a reboot or shutdown inside Windows.

Never print `/var/lib/windows/password.env` or the password in it.
