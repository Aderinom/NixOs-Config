{vars, ...}: {
  programs._1password.enable = true;

  programs._1password-gui.enable = true;
  programs._1password-gui.polkitPolicyOwners = [vars.username];

  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        chromium
      '';
      mode = "0755";
    };
  };
}
