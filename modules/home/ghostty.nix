{ config, pkgs, ... }: {
  programs.ghostty = {
    enable = true;
    settings = {
      theme = "Catppuccin Mocha";

      font-family = "JetBrainsMono Nerd Font";
      font-size = 12;
      cursor-style = "block";
      cursor-style-blink = false;

      window-padding-x = 12;
      window-padding-y = 12;
      window-padding-balance = true;

      quit-after-last-window-closed = true;
      quit-after-last-window-closed-delay = 0;
      confirm-close-surface = false;
      copy-on-select = "clipboard";
      mouse-hide-while-typing = true;
      clipboard-trim-trailing-spaces = true;

      scrollback-limit = 100000;

      shell-integration = "detect";
      shell-integration-features = "cursor,sudo,title,ssh-env,ssh-terminfo";
    };
  };
}
