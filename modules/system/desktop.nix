{ config, pkgs, lib, ... }: {
  hardware.i2c.enable = true;  # DDC/CI brightness control via ddcutil

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [ swaylock swayidle ];
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    # No config block: programs.sway already sets xdg.portal.config.sway with
    # ScreenCast and Screenshot routed to wlr, everything else to gtk, and
    # Inhibit disabled. Overriding `default` to prefer wlr for every interface
    # gained nothing - wlr only implements the two - and needed a mkForce to
    # fight the upstream value.
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

  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Noto Sans" ];
    serif      = [ "Noto Serif" ];
    monospace  = [ "JetBrainsMono Nerd Font" ];
    emoji      = [ "Noto Color Emoji" ];
  };

  programs.dconf.enable = true;

  services.udisks2.enable = true;

  # Allow `-o allow_other` on FUSE mounts so a root-mounted apfs-fuse volume
  # (encrypted macOS disk) is browsable by the normal user in yazi.
  programs.fuse.userAllowOther = true;

  # Let wheel users mount/unmount/eject internal (non-removable) disks via
  # udisks2 without an admin password. yazi's mount manager (=v) calls
  # `udisksctl --no-user-interaction`, which cannot show a polkit prompt; on a
  # single-user physical workstation, granting wheel directly is the pragmatic
  # way to make =v work for fixed disks (ntfs/hfsplus/exfat).
  # NOTE: APFS is intentionally NOT covered here. The macOS disk is
  # FileVault-encrypted, which the in-kernel linux-apfs-rw driver refuses
  # ("encrypted volumes are not supported"), so udisks/=v can't mount it.
  # Read it with apfs-fuse (below), which handles encryption with a password.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel") && (
            action.id == "org.freedesktop.udisks2.filesystem-mount" ||
            action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
            action.id == "org.freedesktop.udisks2.filesystem-unmount-others" ||
            action.id == "org.freedesktop.udisks2.eject-media" ||
            action.id == "org.freedesktop.udisks2.power-off-drive")) {
        return polkit.Result.YES;
      }
    });
  '';

  environment.systemPackages = with pkgs; [
    grim slurp wl-clipboard
    polkit_gnome
    qt5.qtwayland
    qt6.qtwayland
    udiskie
    networkmanagerapplet
    apfs-fuse   # read encrypted/macOS APFS disks (FUSE, read-only, prompts for password)
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL              = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    QT_QPA_PLATFORM             = "wayland";
    QT_QPA_PLATFORMTHEME        = "gtk3";
  };
}
