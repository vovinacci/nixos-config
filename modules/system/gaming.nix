{ pkgs, ... }: {
  # Steam needs the system-level module, not a plain package: it sets up the
  # FHS wrapper, the udev rules for controllers (hardware.steam-hardware), and
  # the 32-bit graphics stack.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
    # GE-Proton as a Steam compatibility tool, updated with nixpkgs. Steam lists
    # it under one stable name ("GE-Proton"), so a game set to it keeps working
    # across updates, but only the current version is available. Heroic and
    # Lutris download their own.
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  environment.systemPackages = with pkgs; [
    # strategy
    openra
    fheroes2
    openxcom
    vcmi
    wesnoth

    # GOG / Epic launcher
    heroic
    lutris

    # tools
    dosbox-staging
    innoextract      # extract GOG installers
    winetricks
  ];
}
