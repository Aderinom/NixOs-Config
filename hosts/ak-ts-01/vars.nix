# Per-host vars, merged over flake-variables.nix.
# Keep the state versions at the release this machine was installed with:
# https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
{
  gitMail = "aaron.kelbsch@anapaya.net";
  gitName = "Aaron Kelbsch";

  features = {
    desktop.hyprland = true;
    normal-use = true;
    claude = true;
    professional-use = true;
    sshd = true;
    windows-vm = true;
  };

  ssh-authorized-keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCM1mnqlNoBHaOORgvD7O537wuV9A+rnVDqUFsQ3xKmgr23MBHlsXD7LFnVmqjw3WfJ9YZRQmZtK3PD0mZqQMfSwzg0nReFPDMqPThJ6UR7AGL9oRBJaTv56eVs5PkfZDVZe+qlnATHaITTezRun6TQuvR3c/JhQuK+S7d7z1VgXJ0pLng6aRWFmW5kg459tmfJ0dUHppK8C6LMV4pE+9qY21z8qg0+ilReuuaW+91D+ZR2nXTK3tM/4d3PBMnbM1gOKzcq7kZEZ1y1KgVQy8g6jb5qhNfUYxF8iqW07m+EXAUahgD7M+a/LbcQHq1U5XY15oQ6zT47TolatGcJqHX691V5zbEGAni8Sr6H+DIpXPATs8GEIEpPdsBsmDgRfHpyXT5lQ2jQId7wpTK3sL5vGPW5QDP/8XHG1PzXU52H8VpkaQx6TwONuVugG4vFjcDUU4HrwelgJefEAAqyi9NUkt9HDCL81Jj2PrsQHsaKXI1B2+Dkiew9TWk38Roq+7WGP0WBiboYI0bnxGPwhuMmvm7rFCQxKH9teZJvjl1/HPRiCZd4RE1e1YZu9mcNhVF02kqaY8jr4QnBe/ZvCE0GLmckwKvaxfCHP4dgCy02WbUWx8UOVLOFZAuEO7d7/u2y9tfz1KdGth3dZeoG7HvFzsRw68tdcer4lLNRdRWykw== akelbsch-private"
  ];

  nix-state-version = "24.11";
  home-mgr-state-version = "25.05";
}
