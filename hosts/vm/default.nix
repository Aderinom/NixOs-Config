{username, ...}: {
  imports = [];
  # Hardcode password so we can access the vm
  users.mutableUsers = false;
  users.users.${username}.password = "password";
}
