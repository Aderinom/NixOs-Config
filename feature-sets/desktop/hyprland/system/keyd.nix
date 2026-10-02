{
  services.keyd.enable = false;
  environment.etc."keyd/default.conf".source = ./keyd.config;
}
