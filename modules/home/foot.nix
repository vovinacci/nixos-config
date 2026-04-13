{ config, ... }: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=11";
        pad  = "12x12";
      };
      mouse = {
        hide-when-typing = "yes";
      };
    };
  };
}
