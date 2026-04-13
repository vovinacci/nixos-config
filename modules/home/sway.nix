{ config, pkgs, ... }: {
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4";
      terminal = "foot";
      menu     = "wofi --show drun";

      output = {
        "DP-2" = {
          mode    = "3840x2160@143.963Hz";
          scale   = "1.5";
        };
      };

      keybindings = let mod = "Mod4"; in {
        "${mod}+Return"       = "exec foot";
        "${mod}+d"            = "exec wofi --show drun";
        "${mod}+q"            = "kill";
        "${mod}+Shift+c"      = "reload";
        "${mod}+Shift+e"      = "exec swaymsg exit";
        "${mod}+h"            = "focus left";
        "${mod}+j"            = "focus down";
        "${mod}+k"            = "focus up";
        "${mod}+l"            = "focus right";
        "${mod}+Shift+h"      = "move left";
        "${mod}+Shift+j"      = "move down";
        "${mod}+Shift+k"      = "move up";
        "${mod}+Shift+l"      = "move right";
        "${mod}+s"            = "layout stacking";
        "${mod}+w"            = "layout tabbed";
        "${mod}+e"            = "layout toggle split";
        "${mod}+f"            = "fullscreen toggle";
        "${mod}+1"            = "workspace number 1";
        "${mod}+2"            = "workspace number 2";
        "${mod}+3"            = "workspace number 3";
        "${mod}+4"            = "workspace number 4";
        "${mod}+5"            = "workspace number 5";
        "${mod}+Shift+1"      = "move container to workspace number 1";
        "${mod}+Shift+2"      = "move container to workspace number 2";
        "${mod}+Shift+3"      = "move container to workspace number 3";
        "${mod}+Shift+4"      = "move container to workspace number 4";
        "${mod}+Shift+5"      = "move container to workspace number 5";
        "Print"               = "exec grim -g \"$(slurp)\" - | wl-copy";
      };

      bars = [{ command = "waybar"; }];
      gaps = { inner = 6; outer = 4; };
      window.border = 2;
    };
  };
}
