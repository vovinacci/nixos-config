{ config, ... }: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=13";
        pad  = "12x12";
      };
      mouse = {
        hide-when-typing = "yes";
      };
    };
  };
}
