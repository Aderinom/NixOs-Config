{pkgs, ...}: {
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # lowLatency.enable = true;
  };
  hardware.alsa.enablePersistence = true;
  hardware.firmware = [pkgs.scarlett2-firmware];
  environment.systemPackages = with pkgs; [
    pulseaudioFull
    scarlett2-firmware
  ];
}
