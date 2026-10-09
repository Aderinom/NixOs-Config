# Installs the Command Line Tools, Nix, rustup, and the packages below in the macOS VM, over SSH as the user dev.
#
# The service waits until setup.sh has run in macOS and SSH answers.
# If this file changes, nixos-rebuild switch restarts the service. To run it again by hand:
#   systemctl restart macos-provision
# The Nix profile of dev holds exactly the packages below. Full Xcode stays a manual install.
{
  lib,
  pkgs,
  ...
}: let
  stateDir = "/var/lib/macos";

  # nixpkgs 26.05 is the last release with x86_64-darwin packages. Support ends with 2026.
  nixpkgs = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  # Attribute names in nixpkgs, installed into the Nix profile of dev.
  packages = [
    "direnv"
    "nix-direnv"
  ];

  provisionScript = pkgs.writeText "macos-provision.sh" ''
    set -eu

    nix=/nix/var/nix/profiles/default/bin/nix

    # Replaces the marked block in a file with stdin and sets changed=1 if the file changed.
    # The optional second argument runs the writes through sudo. sh needs the definition before the first call.
    set_block() {
      file=$1
      writer=''${2:-}
      begin="# BEGIN macos-provision"
      end="# END macos-provision"
      new=$(mktemp)

      # Old content without the block, then the new block.
      if [ -e "$file" ]; then
        sed "/^$begin\$/,/^$end\$/d" "$file" > "$new"
      fi
      { echo "$begin"; cat; echo "$end"; } >> "$new"

      # Writing in place keeps the owner and mode of an existing file.
      if ! cmp -s "$new" "$file"; then
        $writer mkdir -p "$(dirname "$file")"
        $writer cp "$new" "$file"
        changed=1
      fi

      rm -f "$new"
    }

    # Command Line Tools: compilers, linker, SDK, and git. softwareupdate lists them only with the placeholder file.
    if ! xcode-select -p > /dev/null 2>&1; then
      placeholder=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
      touch "$placeholder"
      label=$(softwareupdate -l 2> /dev/null | sed -n 's/^\* Label: \(Command Line Tools.*\)$/\1/p' | sort -V | tail -n 1)
      if [ -z "$label" ]; then
        echo "softwareupdate lists no Command Line Tools" >&2
        exit 1
      fi
      sudo softwareupdate -i "$label"
      rm -f "$placeholder"
    fi

    # Nix, multi-user. The installer calls sudo itself and must not run as root.
    if [ ! -x "$nix" ]; then
      curl -fsSL https://nixos.org/nix/install -o /tmp/nix-install
      sh /tmp/nix-install --daemon --yes --no-channel-add
      rm -f /tmp/nix-install
    fi

    # Flakes, and dev as a trusted user, so that project flakes can set their own substituters.
    changed=0
    set_block /etc/nix/nix.conf sudo <<EOF
    experimental-features = nix-command flakes
    trusted-users = root $(id -un)
    EOF
    if [ "$changed" = 1 ]; then
      sudo launchctl kickstart -k system/org.nixos.nix-daemon
    fi

    # Non-interactive SSH commands read only ~/.zshenv, so Nix goes on PATH there. rustup adds cargo itself.
    set_block "$HOME/.zshenv" <<'EOF'
    if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    EOF

    # direnv with nix-direnv for `use flake`, if the package list has them.
    set_block "$HOME/.zshrc" <<'EOF'
    if command -v direnv > /dev/null; then
      eval "$(direnv hook zsh)"
    fi
    EOF
    set_block "$HOME/.config/direnv/direnvrc" <<'EOF'
    if [ -e "$HOME/.nix-profile/share/nix-direnv/direnvrc" ]; then
      source "$HOME/.nix-profile/share/nix-direnv/direnvrc"
    fi
    EOF

    # nixpkgs in flake references means the last release with Intel macOS packages.
    "$nix" registry add nixpkgs ${nixpkgs}

    # rustup, for repos whose flake has no x86_64-darwin.
    if [ ! -x "$HOME/.cargo/bin/rustup" ]; then
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi

    # Rebuild the profile from the list, so that dropped packages go away.
    "$nix" profile remove --all
    ${lib.optionalString (packages != []) ''"$nix" profile add ${lib.concatMapStringsSep " " (p: "${nixpkgs}#${p}") packages}''}
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
  systemd.services.macos-provision = {
    description = "Install the dev tools in the macOS VM";
    requires = ["docker-macos.service"];
    after = ["docker-macos.service"];
    partOf = ["docker-macos.service"];
    # multi-user.target makes the first switch start it. docker-macos.service makes macos-start start it.
    wantedBy = ["multi-user.target" "docker-macos.service"];
    # A simple service lets nixos-rebuild finish while this waits for the manual install.
    # RemainAfterExit keeps it active after success, so a changed package list restarts it.
    serviceConfig = {
      Type = "simple";
      RemainAfterExit = true;
    };
    script = ''
      until ${ssh} -p 2223 ${sshOpts} dev@127.0.0.1 exit 2>/dev/null; do
        sleep 30
      done
      ${pkgs.openssh}/bin/scp -P 2223 ${sshOpts} ${provisionScript} dev@127.0.0.1:macos-provision.sh
      ${ssh} -p 2223 ${sshOpts} dev@127.0.0.1 sh macos-provision.sh
    '';
  };
}
