{ pkgs, ... }: {
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
