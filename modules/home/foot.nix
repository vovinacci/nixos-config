{ config, pkgs, ... }: {
  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        font             = "JetBrainsMono Nerd Font:size=12";
        pad              = "12x12";
        selection-target = "both";
      };
      mouse = {
        hide-when-typing = "yes";
      };
    };
  };
}
