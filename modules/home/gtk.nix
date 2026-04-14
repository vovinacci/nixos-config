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

  home.pointerCursor = {
    name    = "catppuccin-mocha-dark-cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
    size    = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  home.sessionVariables = {
    XCURSOR_THEME = "catppuccin-mocha-dark-cursors";
    XCURSOR_SIZE  = "24";
  };

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme    = "catppuccin-mocha-blue-standard+default";
    icon-theme   = "Papirus-Dark";
    cursor-theme = "catppuccin-mocha-dark-cursors";
    cursor-size  = 24;
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
      "video/mp4"             = "mpv.desktop";
      "video/mkv"             = "mpv.desktop";
      "audio/mpeg"            = "mpv.desktop";
    };
  };
}
