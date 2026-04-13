{ config, pkgs, ... }: {
  hardware.steam-hardware.enable = true;

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [ swaylock swayidle ];
  };

  # screen share support
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];
    config.common.default = "wlr";
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
  ];

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND          = "1";
    NIXOS_OZONE_WL              = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };
}
