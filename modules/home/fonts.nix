{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    nerd-fonts.fira-mono
    nerd-fonts.iosevka
    nerd-fonts.meslo-lg
    commit-mono
  ];
}
