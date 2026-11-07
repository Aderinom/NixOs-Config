# Hand-written tuning for the hardware of this machine. nixos-generate-config owns hardware-configuration.nix.
{pkgs, ...}: {
  boot.initrd.kernelModules = ["amdgpu"];
  boot.kernelModules = [
    "nct6775" # Super I/O sensor chip on the TUF B450-Plus (fan speeds, VRM/board temps)
  ];
  boot.kernelParams = [
    # Zen 3 supports the modern amd_pstate driver. "active" (EPP) generally
    # gives better idle power + comparable performance vs acpi-cpufreq.
    # Requires "CPPC" enabled in BIOS (Advanced > AMD CBS). If boost behaves
    # oddly, try "amd_pstate=guided" instead.
    "amd_pstate=active"
    # Unlock overclocking/undervolting sysfs knobs for LACT.
    # 0xffffffff enables all ppfeaturemask bits; harmless but explicit.
    # Omit this if you only want monitoring and stock fan control.
    "amdgpu.ppfeaturemask=0xffffffff"
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.lact.enable = true; # daemon + GUI, the Linux TriXX/Adrenalin substitute

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device",ATTR{idVendor}=="320f", ATTR{idProduct}=="5055", ATTR{power/wakeup}="disabled"
  '';

  environment.systemPackages = with pkgs; [
    alsa-scarlett-gui
  ];
}
