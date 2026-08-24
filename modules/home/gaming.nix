{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    # strategy
    openra
    fheroes2

    # GOG / Epic launcher
    heroic
    lutris

    # proton for broader library (steam itself is programs.steam, see
    # modules/system/gaming.nix)
    protonup-qt      # manage proton versions

    # tools
    innoextract      # extract GOG installers
    winetricks
  ];
}
