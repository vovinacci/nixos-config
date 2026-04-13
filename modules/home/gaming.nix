{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    # strategy
    openra
    fheroes2

    # GOG / Epic launcher
    heroic
    lutris

    # steam + proton for broader library
    steam
    protonup-qt      # manage proton versions

    # tools
    innoextract      # extract GOG installers
    winetricks
  ];

  # steam needs this
  hardware.steam-hardware.enable = true;
}
