{ config, pkgs, ... }: {
  imports = [
    ../modules/home/common.nix
    ../modules/home/neovim.nix
    ../modules/home/sway.nix
    ../modules/home/waybar.nix
    ../modules/home/foot.nix
    ../modules/home/firefox.nix
    ../modules/home/dev.nix
    ../modules/home/fonts.nix
    ../modules/home/media.nix
    ../modules/home/apps.nix
    ../modules/home/gaming.nix
    ../modules/home/mako.nix
    ../modules/home/gtk.nix
  ];

  home.username      = "vovin";
  home.homeDirectory = "/home/vovin";
  home.stateVersion  = "26.05";

  home.packages = with pkgs; [
    jetbrains.idea
  ];
}
