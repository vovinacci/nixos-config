{ pkgs, ... }: {
  # Steam needs the system-level module, not a home.packages entry: it sets up
  # the FHS wrapper, the udev rules for controllers (hardware.steam-hardware),
  # and the 32-bit graphics stack. The user-facing launchers and Proton tooling
  # stay in modules/home/gaming.nix.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
  };
}
