{ config, pkgs, ... }: {
  gtk = {
    enable = true;
    theme = {
      name    = "catppuccin-mocha-blue-standard+default";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        variant = "mocha";
      };
    };
    iconTheme = {
      name    = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name    = "catppuccin-mocha-dark-cursors";
      package = pkgs.catppuccin-cursors.mochaDark;
      size    = 24;
    };
  };

  home.sessionVariables = {
    XCURSOR_THEME = "catppuccin-mocha-dark-cursors";
    XCURSOR_SIZE  = "24";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html"             = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "application/pdf"       = "firefox.desktop";
      "image/png"             = "imv.desktop";
      "image/jpeg"            = "imv.desktop";
      "video/mp4"             = "mpv.desktop";
      "video/mkv"             = "mpv.desktop";
      "audio/mpeg"            = "mpv.desktop";
    };
  };
}
