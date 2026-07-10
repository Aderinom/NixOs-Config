{pkgs, ...}: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      # Video accelaration
      intel-media-driver
      nvidia-vaapi-driver
      (intel-vaapi-driver.override {enableHybridCodec = true;})
      # VDPAU to VAAPI Bridge
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  hardware.enableRedistributableFirmware = true;
}
