{vars, ...}: {
  imports = [];
  # Hardcode password so we can access the vm
  users.mutableUsers = false;
  users.users.${vars.username}.password = "password";
}
