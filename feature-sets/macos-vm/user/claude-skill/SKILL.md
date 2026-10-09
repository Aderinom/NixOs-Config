---
name: macos-vm
description: Run commands, copy files, and build code in the local Intel macOS 15 VM over SSH. Use when a task needs macOS, for example a macOS or iOS build with Xcode, a cargo build for an Apple target, or a check of macOS behavior.
---

# macOS VM

An Intel macOS 15 VM runs in the Docker container `macos`. The NixOS feature
set `~/.nixos-config/feature-sets/macos-vm` defines it. That folder is the
source of truth for ports, the user, and the package list.

## Check first

Run `command -v macos-ssh`. If it finds nothing, the feature set is off. Stop
and tell the user.

If `macos-ssh true` fails, check the state:

```sh
systemctl status docker-macos macos-provision --no-pager
journalctl -u macos-provision -n 30 --no-pager
```

- If `docker-macos` is inactive, the VM is off. Ask the user before you run
  `macos-start`.
- If `macos-provision` still loops on SSH, the user has not finished the
  manual install or `setup.sh` yet. Point them to the web console at
  http://127.0.0.1:8007 and the header of `system/setup/setup.sh`.
- If `macos-ssh` fails with `Host key verification failed`, provisioning has
  not logged in yet.

## Run commands

`macos-ssh <command>` runs the command as `dev` in `zsh` and returns its exit
code. Pass the command as one single-quoted string.

- Non-interactive commands read only `~/.zshenv`. Nix and cargo are on `PATH`
  there. The direnv hook is not, so use `nix develop -c <cmd>` or
  `direnv exec <dir> <cmd>`.
- `dev` has sudo without a password. Use it only for what the task needs.

## Nix on Intel macOS

The VM is `x86_64-darwin`. nixpkgs 26.05 is the last release with packages
for it.

- The flake registry maps `nixpkgs` to `nixpkgs-26.05-darwin`.
- If a project flake lists `x86_64-darwin` but pins a newer nixpkgs, try
  `nix develop --override-input nixpkgs github:NixOS/nixpkgs/nixpkgs-26.05-darwin`.
- If the flake does not list `x86_64-darwin`, use `rustup` and the
  Command Line Tools directly, and tell the user that the flake lacks the
  system.
- Do not add packages with `nix profile add`. Provisioning resets the profile
  to the list in `system/01-provision.nix`. Tell the user to add them there.

## Copy files

Use `scp` with the same host key file as `macos-ssh`:

```sh
scp -P 2223 -o UserKnownHostsFile=/var/lib/macos/provision/known_hosts \
  -o StrictHostKeyChecking=yes -r ./project dev@127.0.0.1:src/project
```

Remote paths without a leading `/` start in `/Users/dev`. Swap source and
destination to copy back.

`~/macshare` on the host is a 9p share, mounted in macOS at boot. Do not
build from it: 9p is slow, and files from macOS come out owned by root on the
host.

## Xcode and iOS

Full Xcode is a manual install that needs the user's Apple ID. Check it with
`macos-ssh 'xcode-select -p'`. If it prints
`/Library/Developer/CommandLineTools`, only the Command Line Tools exist, and
iOS builds fail. Ask the user to install Xcode.

## Ask the user first

- before `macos-start` or `macos-stop`;
- before anything that deletes or changes `/var/lib/macos`;
- before a reboot or shutdown inside macOS;
- before you use sudo in macOS for anything outside the task.
