{
  boot.kernelParams = ["elevator=bfq"];

  boot.kernel.sysctl = {
    "vm.dirty_ratio" = 5;
    "vm.dirty_background_ratio" = 2;
  };
}
