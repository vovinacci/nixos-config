{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    slack
    signal-desktop
    zoom-us
    teams-for-linux
    vscode
  ];
}
