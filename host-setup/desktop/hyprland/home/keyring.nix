{
  pkgs,
  inputs,
  username,
  ...
}: {
  services.gnome-keyring.enable = true;
}
