{ config, pkgs, lib, ... }: {
  hardware.i2c.enable = true;  # DDC/CI brightness control via ddcutil

  # System side of the sway session only: PAM for swaylock, polkit, XWayland,
  # and the wlr + gtk portals. The sway binary itself comes from home-manager
  # (wayland.windowManager.sway.package), which is the one the session runs -
  # it is first on PATH - so a second copy here was dead weight.
  programs.sway = {
    enable  = true;
    package = null;
    # Empty on purpose: the upstream default (swaylock, swayidle, foot, wmenu,
    # ...) would duplicate what home-manager's programs.swaylock and
    # services.swayidle already install.
    extraPackages = [ ];
  };

  xdg.portal = {
    enable = true;
    # programs.sway already adds the wlr and gtk portals and sets
    # xdg.portal.config.sway: ScreenCast and Screenshot to wlr, everything else
    # to gtk, Inhibit disabled. Only Secret is added here, since the gtk portal
    # does not implement it.
    config.sway."org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
  };

  # Secret Service for Electron apps (Slack, VSCode) and libsecret. Unlocked at
  # login through greetd's PAM stack, which includes `login`.
  services.gnome.gnome-keyring.enable = true;
  # gcr-ssh-agent defaults to on with gnome-keyring. gpg-agent is the SSH agent
  # here (YubiKey), and only one can own SSH_AUTH_SOCK.
  services.gnome.gcr-ssh-agent.enable = false;

  # Screencast lifecycle is otherwise invisible: Electron apps (Slack) can stop
  # sharing in their UI while the portal session stays open. exec_after fires
  # only once every screencast has really ended, so a missing "ended"
  # notification means the app leaked its session - `$mod+Shift+s` kills it.
  xdg.portal.wlr.settings.screencast = {
    exec_before = "${pkgs.libnotify}/bin/notify-send -a screencast 'Screen sharing started'";
    exec_after  = "${pkgs.libnotify}/bin/notify-send -a screencast 'Screen sharing ended'";
    # The output runs at 144 Hz; viewers gain nothing above 60.
    max_fps = 60;
  };

  services.greetd = {
    enable = true;
    # Gives tuigreet the TTY to itself, so kernel and service messages (the
    # host raises consoleLogLevel) do not draw over the greeter.
    useTextGreeter = true;
    settings.default_session.command =
      "${pkgs.tuigreet}/bin/tuigreet --time --cmd sway";
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
    grim slurp
    apfs-fuse   # read encrypted/macOS APFS disks (FUSE, read-only, prompts for password)
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL              = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    QT_QPA_PLATFORM             = "wayland;xcb";
    QT_QPA_PLATFORMTHEME        = "gtk3";
  };
}
