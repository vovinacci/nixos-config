{ config, pkgs, ... }: {
  hardware.bluetooth = {
    enable = true;
    # Experimental exposes battery levels of connected devices over D-Bus.
    settings.General.Experimental = true;
  };
  services.blueman.enable = true;
}
