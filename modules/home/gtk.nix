{ config, pkgs, ... }: {
  gtk = {
    enable = true;
    font = {
      name = "Noto Sans";
      size = 12;
    };
    # Community Catppuccin theme (Fausto-Korpsvart); the official catppuccin/gtk
    # port was archived upstream in June 2024. Mocha is its default flavor.
    theme = {
      name    = "Catppuccin-GTK-Blue-Dark";
      package = pkgs.magnetic-catppuccin-gtk.override {
        accent = [ "blue" ];
        shade  = "dark";
      };
    };
    iconTheme = {
      name    = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    # Also writes the org/gnome/desktop/interface dconf keys (color-scheme,
    # gtk-theme, icon-theme, cursor-theme, cursor-size, font-name).
    colorScheme = "dark";
  };

  # Single source for the cursor: sets gtk.cursorTheme, XCURSOR_THEME/SIZE,
  # and sway's seat cursor (greetd starts sway without the session variables).
  home.pointerCursor = {
    enable  = true;
    name    = "catppuccin-mocha-dark-cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
    size    = 24;
    gtk.enable  = true;
    x11.enable  = true;
    sway.enable = true;
  };

  programs.swaylock = {
    enable   = true;
    settings = {
      color               = "1a1a2e";
      indicator-radius    = 100;
      indicator-thickness = 7;
      inside-color        = "1a1a2e";
      ring-color          = "89b4fa";
      key-hl-color        = "a6e3a1";
      line-color          = "00000000";
      text-color          = "cdd6f4";
      show-failed-attempts = true;
    };
  };

  xdg.userDirs = {
    enable             = true;
    createDirectories  = true;
    desktop            = null;
    templates          = null;
    publicShare        = null;
    documents          = "${config.home.homeDirectory}/Documents";
    download           = "${config.home.homeDirectory}/Downloads";
    music              = "${config.home.homeDirectory}/Music";
    pictures           = "${config.home.homeDirectory}/Pictures";
    videos             = "${config.home.homeDirectory}/Videos";
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
      "video/mp4"             = "vlc.desktop";
      "video/x-matroska"      = "vlc.desktop";
      "audio/mpeg"            = "vlc.desktop";
    };
  };
}
