{ config, pkgs, ... }: {
  # Logitech mouse/keyboard management
  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;  # solaar GUI
  };

  environment.systemPackages = with pkgs; [
    solaar
  ];
}
