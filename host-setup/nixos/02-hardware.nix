{pkgs, ...}: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      # Video accelaration
      intel-media-driver
      (vaapiIntel.override {enableHybridCodec = true;})
      # VDPAU to VAAPI Bridge
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  hardware.enableRedistributableFirmware = true;
}
