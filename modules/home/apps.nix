{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    zip
    unzip
    p7zip
    playerctl
    pavucontrol
    slack
    signal-desktop
    telegram-desktop
    karere
    zoom-us
    teams-for-linux
    vscode
    jetbrains.idea
  ];
}
