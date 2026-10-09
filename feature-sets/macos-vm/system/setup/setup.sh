#!/bin/sh
# One-time bootstrap inside macOS, after the install. Run it in Terminal from the account you created:
#   sudo mount_9p shared && sudo sh /Volumes/shared/.setup/setup.sh
# It installs the SSH keys, gives that account sudo without a password, and mounts the share at every boot.
set -eu

# If this runs without sudo, there is no account to set up.
if [ "$(id -u)" -ne 0 ] || [ -z "${SUDO_USER:-}" ]; then
  echo "Run it with sudo from your own account." >&2
  exit 1
fi

user=$SUDO_USER
home=$(dscl . -read "/Users/$user" NFSHomeDirectory | awk '{print $2}')
here=$(cd "$(dirname "$0")" && pwd)

# SSH keys: the host user and macos-provision.service.
install -d -m 700 -o "$user" -g staff "$home/.ssh"
install -m 600 -o "$user" -g staff "$here/authorized_keys" "$home/.ssh/authorized_keys"

# Sudo without a password, so that macos-provision.service can install the Command Line Tools and Nix.
rule=/etc/sudoers.d/$user
printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$user" > "$rule.tmp"
chmod 440 "$rule.tmp"
visudo -cf "$rule.tmp" > /dev/null
mv "$rule.tmp" "$rule"

# Share at every boot. The 9p device can show up after launchd starts the job, so it retries.
cat > /Library/LaunchDaemons/local.mount-9p-shared.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>local.mount-9p-shared</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>-c</string>
    <string>for i in 1 2 3 4 5 6; do /sbin/mount_9p shared &amp;&amp; exit 0; sleep 5; done; exit 1</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF
chown root:wheel /Library/LaunchDaemons/local.mount-9p-shared.plist
chmod 644 /Library/LaunchDaemons/local.mount-9p-shared.plist

# Remote Login: if Terminal lacks Full Disk Access, systemsetup fails, and the switch in System Settings remains.
if ! systemsetup -setremotelogin on > /dev/null 2>&1; then
  echo "Turn on Remote Login: System Settings > General > Sharing > Remote Login."
fi

echo "Done. macos-provision.service on the host takes over once SSH answers."
