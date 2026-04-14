{ config, pkgs, lib, ... }: {
  hardware.steam-hardware.enable = true;

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [ swaylock swayidle ];
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config = {
      sway = {
        default = lib.mkForce [ "wlr" "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
      };
    };
  };

  security.pam.services.swaylock = {};

  services.greetd = {
    enable = true;
    settings.default_session.command =
      "${pkgs.tuigreet}/bin/tuigreet --time --cmd sway";
  };

  # pipewire screen capture for WebRTC
  services.pipewire.extraConfig.pipewire = {
    "10-screencast" = {
      "stream.properties" = {
        "node.latency" = "1024/48000";
      };
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];

  environment.systemPackages = with pkgs; [
    waybar wofi foot
    grim slurp wl-clipboard mako
    firefox
    polkit_gnome
    wlsunset
  ];

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND          = "1";
    NIXOS_OZONE_WL              = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };
}
