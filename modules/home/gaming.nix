{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    # strategy
    openra
    fheroes2

    # GOG / Epic launcher
    heroic
    lutris

    # GE-Proton comes from programs.steam.extraCompatPackages for Steam
    # (modules/system/gaming.nix); Heroic and Lutris download their own.

    # tools
    innoextract      # extract GOG installers
    winetricks
  ];
}
