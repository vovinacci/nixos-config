{ config, pkgs, ... }: {
  # Logitech mouse/keyboard management. Replaces the old
  # hardware.logitech.wireless.enableGraphical, which was renamed to
  # programs.solaar.enable upstream. The option installs the package and turns
  # on hardware.logitech.wireless (udev rules), so neither is listed here.
  programs.solaar = {
    enable = true;
    # Runs solaar in the background (tray icon) so device settings and rules
    # apply after login; the sway session runs no XDG autostart of its own.
    userService.enable = true;
  };
}
