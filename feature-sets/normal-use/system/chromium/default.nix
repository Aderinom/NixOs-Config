{
  programs.chromium.enable = true;
  programs.chromium.initialPrefs = {
    "PasswordManagerEnabled" = false;
    "SpellcheckEnabled" = true;
    "SpellcheckLanguage" = [
      "de"
      "en-US"
    ];
  };
}
