{ config, pkgs, ... }: {
  programs.ghostty = {
    enable = true;
    # Terminals are started directly by sway ($mod+Return), not through the
    # D-Bus activated service, which only produced a duplicate-name warning.
    systemd.enable = false;
    settings = {
      theme = "Catppuccin Mocha";

      font-family = "JetBrainsMono Nerd Font";
      font-size = 12;
      cursor-style = "block";
      cursor-style-blink = false;

      window-padding-x = 12;
      window-padding-y = 12;
      window-padding-balance = true;

      confirm-close-surface = false;
      copy-on-select = "clipboard";
      mouse-hide-while-typing = true;
      clipboard-trim-trailing-spaces = true;

      shell-integration = "detect";
      shell-integration-features = "cursor,sudo,title,ssh-env,ssh-terminfo";
    };
  };
}
