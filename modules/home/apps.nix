{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    slack
    signal-desktop
    telegram-desktop
    wasistlos
    zoom-us
    teams-for-linux
    vscode
  ];
}
