{
  services.keyd.enable = true;
  environment.etc."keyd/default.conf".source = ./keyd.config;
}
