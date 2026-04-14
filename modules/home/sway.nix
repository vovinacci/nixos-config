{ config, pkgs, ... }: {
  home.packages = with pkgs; [ cliphist swayr ];

  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4";
      input = {
        "*" = {
          xkb_layout  = "us,ua";
          xkb_options = "grp:ctrl_space_toggle,compose:ralt";
        };
      };
      startup = [
        { command = "${pkgs.swayr}/bin/swayrd"; }
        { command = "wl-paste --watch cliphist store"; }
      ];
      terminal = "foot";
      menu     = "wofi --show drun";
      fonts = {
        names = [ "JetBrainsMono Nerd Font" ];
        size  = 11.0;
      };
      output = {
        "DP-2" = {
          mode  = "3840x2160@143.963Hz";
          scale = "1.5";
        };
      };
      window.border = 2;
      bars = [{ command = "waybar"; }];
      focus.followMouse = false;
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
	"Alt+Tab"             = "exec ${pkgs.swayr}/bin/swayr next-window current-workspace";
        "Alt+Shift+Tab"       = "exec ${pkgs.swayr}/bin/swayr prev-window current-workspace";
        "${mod}+Shift+h"      = "move left";
        "${mod}+Shift+j"      = "move down";
        "${mod}+Shift+k"      = "move up";
        "${mod}+Shift+l"      = "move right";
        "${mod}+s"            = "layout stacking";
        "${mod}+w"            = "layout tabbed";
        "${mod}+e"            = "layout toggle split";
        "${mod}+f"            = "fullscreen toggle";
        "${mod}+r"            = "mode resize";
        "${mod}+minus"        = "scratchpad show";
        "${mod}+Shift+minus"  = "move scratchpad";
        "${mod}+space"        = "focus mode_toggle";
        "${mod}+Shift+space"  = "floating toggle";
        "${mod}+1"            = "workspace number 1";
        "${mod}+2"            = "workspace number 2";
        "${mod}+3"            = "workspace number 3";
        "${mod}+4"            = "workspace number 4";
        "${mod}+5"            = "workspace number 5";
        "${mod}+6"            = "workspace number 6";
        "${mod}+7"            = "workspace number 7";
        "${mod}+8"            = "workspace number 8";
        "${mod}+9"            = "workspace number 9";
        "${mod}+0"            = "workspace number 10";
        "${mod}+Shift+1"      = "move container to workspace number 1";
        "${mod}+Shift+2"      = "move container to workspace number 2";
        "${mod}+Shift+3"      = "move container to workspace number 3";
        "${mod}+Shift+4"      = "move container to workspace number 4";
        "${mod}+Shift+5"      = "move container to workspace number 5";
        "${mod}+Shift+6"      = "move container to workspace number 6";
        "${mod}+Shift+7"      = "move container to workspace number 7";
        "${mod}+Shift+8"      = "move container to workspace number 8";
        "${mod}+Shift+9"      = "move container to workspace number 9";
        "${mod}+Shift+0"      = "move container to workspace number 10";
        "${mod}+v"            = "exec cliphist list | wofi --dmenu | cliphist decode | wl-copy";
        "Print"               = "exec grim -g \"$(slurp)\" - | wl-copy";
        "--locked XF86AudioMute"        = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "--locked XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
        "--locked XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
        "--locked XF86AudioMicMute"     = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";
      };
    };
    extraConfig = ''
      output * bg #1a1a2e solid_color
      #for_window [app_id="slack"] floating enable
      exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
      exec systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    '';
  };
}
