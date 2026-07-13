{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;

    package = pkgs.firefox;
    configPath = ".mozilla/firefox";

    # ---------------------------
    # ENFORCED POLICIES
    # ---------------------------
    policies = {
      DisableFirefoxStudies = true;
      DisableTelemetry = true;

      FirefoxSuggest = {
        WebSuggestions = false;
        SponsoredSuggestions = false;
        ImproveSuggest = false;
      };

      Preferences = {
        "browser.urlbar.suggest.searches" = false;
        "browser.urlbar.suggest.quicksuggest" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      };
    };

    # ---------------------------
    # USER PROFILE SETTINGS
    # ---------------------------
    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      settings = {
        # --- PRIVACY & TELEMETRY ---
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.server" = "data:,";
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.newProfilePing.enabled" = false;
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.updatePing.enabled" = false;
        "toolkit.telemetry.bhrPing.enabled" = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "app.shield.optoutstudies.enabled" = false;

        # --- AI & BLOAT OPT-OUT ---
        "browser.ml.enable" = false;
        "browser.ml.chat.enabled" = false;
        "browser.ml.linkPreview.enabled" = false;
        "browser.tabs.groups.smart.enabled" = false;
        "extensions.getAddons.showPane" = false;
        "browser.discovery.enabled" = false;

        # --- UX TWEAKS ---
        "browser.aboutConfig.showWarning" = false;
        "browser.toolbars.bookmarks.visibility" = "always";
        "browser.shell.checkDefaultBrowser" = false;
      };
    };
  };
}
