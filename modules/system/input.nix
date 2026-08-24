{ config, pkgs, ... }: {
  # Logitech mouse/keyboard management
  hardware.logitech.wireless.enable = true;

  # solaar GUI. Replaces the old hardware.logitech.wireless.enableGraphical,
  # which was renamed to programs.solaar.enable upstream. The option installs
  # the package, so it must not also be listed in environment.systemPackages.
  programs.solaar.enable = true;
}
