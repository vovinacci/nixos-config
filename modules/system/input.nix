{ pkgs, ... }: {
  # solaar's two desktop-notification tests fail in the build sandbox since
  # glib 2.88: libnotify needs a D-Bus session, and glib refuses to spawn one
  # without a machine-id ("Cannot spawn a message bus without a machine-id").
  # Skips only those two tests; the other ~657 still run. Remove once the
  # nixpkgs solaar package builds without this (try dropping it on update).
  nixpkgs.overlays = [
    (final: prev: {
      solaar = prev.solaar.overridePythonAttrs (old: {
        disabledTestPaths = (old.disabledTestPaths or [ ]) ++ [
          "tests/logitech_receiver/test_desktop_notifications.py::test_show"
          "tests/solaar/ui/test_desktop_notifications.py::test_show"
        ];
      });
    })
  ];

  # Logitech mouse/keyboard management: udev rules, ltunify, and solaar
  # (enableGraphical). nixos-26.05 has no programs.solaar module yet (it is
  # unstable-only); once it does, programs.solaar.enable with
  # userService.enable replaces both this and the unit below.
  hardware.logitech.wireless = {
    enable          = true;
    enableGraphical = true;
  };

  # Runs solaar in the background (tray icon) so device settings and rules
  # apply after login; the sway session runs no XDG autostart of its own.
  # Same unit as unstable's programs.solaar.userService.
  systemd.user.services.solaar = {
    description = "Solaar, the open source driver for Logitech devices";
    wantedBy    = [ "graphical-session.target" ];
    partOf      = [ "graphical-session.target" ];
    after       = [ "dbus.service" ];
    serviceConfig = {
      Type       = "simple";
      ExecStart  = "${pkgs.solaar}/bin/solaar --window hide --battery-icons regular";
      Restart    = "on-failure";
      RestartSec = "5";
    };
  };
}
