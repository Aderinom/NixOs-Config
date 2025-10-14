{pkgs, ...}: {
  programs.firefox.enable = true;
  programs.firefox.policies = {
    DisableTelemetry = true;
    DisableFirefoxStudies = true;
    EnableTrackingProtection = {
      Value = true;
      Locked = true;
      Cryptomining = true;
      Fingerprinting = true;
    };
    DisablePocket = true;
    DisableFirefoxAccounts = true;
    DisableAccounts = true;
    DisableFirefoxScreenshots = true;
    OverrideFirstRunPage = "";
    OverridePostUpdatePage = "";
    DontCheckDefaultBrowser = true;
    SearchEngines = {
      Default = "Startpage";
    };
    DisplayBookmarksToolbar = "always"; # alternatives: "always" or "newtab"
    DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
    SearchBar = "unified"; # alternative: "separate"

    HardwareAcceleration = true;
    TranslateEnabled = true;

    Homepage.StartPage = "previous-session";

    UserMessaging = {
      UrlbarInterventions = false;
      SkipOnboarding = true;
    };

    FirefoxSuggest = {
      WebSuggestions = false;
      SponsoredSuggestions = false;
      ImproveSuggest = false;
    };
  };

  programs.firefox.policies.Preferences = {
    "browser.urlbar.suggest.searches" = true; # Need this for basic search suggestions
    "browser.urlbar.shortcuts.bookmarks" = true;
    "browser.urlbar.shortcuts.history" = true;
    "browser.urlbar.shortcuts.tabs" = false;

    "browser.tabs.tabMinWidth" = 75; # Make tabs able to be smaller to prevent scrolling

    "browser.urlbar.placeholderName" = "Startpage";
    "browser.urlbar.placeholderName.private" = "Startpage";

    "browser.aboutConfig.showWarning" = false; # No warning when going to config
    "browser.warnOnQuitShortcut" = false;

    "browser.tabs.loadInBackground" = true; # Load tabs automatically

    "media.ffmpeg.vaapi.enabled" = true; # Enable hardware acceleration
    "layers.acceleration.force-enabled" = true;
    "gfx.webrender.all" = true;

    "browser.in-content.dark-mode" = true; # Use dark mode
    "ui.systemUsesDarkTheme" = true;

    "extensions.autoDisableScopes" = 0; # Automatically enable extensions
    "extensions.update.enabled" = false;

    "widget.use-xdg-desktop-portal.file-picker" = 1; # Use new gtk file picker instead of legacy one
  };

  programs.firefox.profiles.default.search.engines = {
    # Disable all the stupid "This time, search with" icons
    amazondotcom-us.metaData.hidden = true;
    bing.metaData.hidden = true;
    ebay.metaData.hidden = true;
    google.metaData.hidden = true;
    wikipedia.metaData.hidden = true;

    nix-packages = {
      name = "Nix Packages";
      urls = [
        {
          template = "https://search.nixos.org/packages";
          params = [
            {
              name = "type";
              value = "packages";
            }
            {
              name = "query";
              value = "{searchTerms}";
            }
          ];
        }
      ];

      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      definedAliases = ["@np"];
    };

    "Startpage" = {
      name = "Startpage";
      urls = [
        {
          template = "https://www.startpage.com/sp/search";
          params = [
            {
              name = "query";
              value = "{searchTerms}";
            }
          ];
        }
      ];
      icon = "https://www.startpage.com/sp/cdn/favicons/favicon-32x32.png";
      definedAliases = ["@sp"];
    };
  };

  programs.firefox.profiles.default.settings = {
    "browser.startup.homepage" = "https://www.startpage.com/do/mypage.pl?prfe=305120bda0739d52a8d4190b5d278bf3e88bacc4a50da4a69ab698ba2dfd33c5142fd92d75e5c92d0ed3f861da4759ecd6c72863e1105b566079ed6ecaba70b977653fe56cb8fd2aefb6e9c7https://www.startpage.com/do/mypage.pl?prfe=305120bda0739d52a8d4190b5d278bf3e88bacc4a50da4a69ab698ba2dfd33c5142fd92d75e5c92d0ed3f861da4759ecd6c72863e1105b566079ed6ecaba70b977653fe56cb8fd2aefb6e9c7";
    "browser.search.defaultenginename" = "Startpage";
    "browser.search.region" = "DE";
    "browser.search.isUS" = false;
    "distribution.searchplugins.defaultLocale" = "en-GB";
    "general.useragent.locale" = "en-GB";
    "browser.bookmarks.showMobileBookmarks" = true;
  };

  programs.firefox.profiles.default.extensions = {
    force = true;
    packages = with pkgs.nur.repos.rycee.firefox-addons; [
      ublock-origin
      istilldontcareaboutcookies
      privacy-badger
      decentraleyes
      cookie-autodelete
      darkreader
      bitwarden
      clearurls
      sponsorblock
      return-youtube-dislikes
      # bypass-paywalls-clean
    ];
    settings."uBlock0@raymondhill.net".settings = {
      selectedFilterLists = [
        "ublock-filters"
        "ublock-badware"
        "ublock-privacy"
        "ublock-unbreak"
        "ublock-quick-fixes"
      ];
    };
  };
}
