{ config, pkgs, lib, ... }:

let
  layoutCycle = pkgs.writeShellScriptBin "layout-cycle" ''
    current=$(${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '
      [recurse(.nodes[]?, .floating_nodes[]?) |
        select(((.nodes // []) + (.floating_nodes // [])) |
          map(select(.focused == true)) | length > 0)
      ] | last | .layout
    ')
    case "$current" in
      splith)   ${pkgs.sway}/bin/swaymsg layout splitv ;;
      splitv)   ${pkgs.sway}/bin/swaymsg layout tabbed ;;
      tabbed)   ${pkgs.sway}/bin/swaymsg layout stacking ;;
      stacking) ${pkgs.sway}/bin/swaymsg layout splith ;;
      *)        ${pkgs.sway}/bin/swaymsg layout splith ;;
    esac
    ${pkgs.procps}/bin/pkill -SIGRTMIN+1 waybar
  '';

  layoutHints = pkgs.writeShellScriptBin "layout-hints" ''
    mode=$(${pkgs.sway}/bin/swaymsg -t get_binding_state | ${pkgs.jq}/bin/jq -r '.name')
    if [ "$mode" = "layout" ]; then
      echo "h H · v V · t tab · s stack · Tab cycle · 1/2/3/4 width · S+1/2/3 height"
    fi
  '';

  layoutInfo = pkgs.writeShellScriptBin "layout-info" ''
    data=$(${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '
      ([recurse(.nodes[]?, .floating_nodes[]?) |
        select(((.nodes // []) + (.floating_nodes // [])) |
          map(select(.focused == true)) | length > 0)
      ] | last) // empty |
      {l: .layout, pw: .rect.width, ph: .rect.height,
       cw: (((.nodes // []) + (.floating_nodes // [])) | map(select(.focused == true)) | first | .rect.width),
       ch: (((.nodes // []) + (.floating_nodes // [])) | map(select(.focused == true)) | first | .rect.height)
      } | "\(.l) \(.pw) \(.ph) \(.cw) \(.ch)"
    ' 2>/dev/null)
    [ -z "$data" ] && exit 0

    read -r layout pw ph cw ch <<< "$data"

    snap() {
      local v=$1 t=$2
      [ "$t" -eq 0 ] && echo "?" && return
      local p=$(( v * 100 / t ))
      if   [ "$p" -le 29 ]; then echo "1/4"
      elif [ "$p" -le 42 ]; then echo "1/3"
      elif [ "$p" -le 57 ]; then echo "1/2"
      elif [ "$p" -le 70 ]; then echo "2/3"
      elif [ "$p" -le 84 ]; then echo "3/4"
      else echo "1/1"
      fi
    }

    case "$layout" in
      splith)   echo "⊞ H  $(snap "$cw" "$pw")" ;;
      splitv)   echo "⊟ V  $(snap "$ch" "$ph")" ;;
      tabbed)   echo "⊠ T" ;;
      stacking) echo "☰ S" ;;
      *)        echo "? $layout" ;;
    esac
  '';
in
{
  home.packages = with pkgs; [ cliphist swayr layoutCycle layoutInfo layoutHints ];

  services.swayidle = {
    enable   = true;
    timeouts = [
      { timeout = 300;
         command = "${pkgs.procps}/bin/pgrep -x swaylock || ${pkgs.swaylock}/bin/swaylock -f";
      }
      { timeout = 600;
        command        = "${pkgs.sway}/bin/swaymsg \"output * dpms off\"";
        resumeCommand  = "${pkgs.sway}/bin/swaymsg \"output * dpms on\"";
      }
    ];
    events = {
      before-sleep = "${pkgs.procps}/bin/pgrep -x swaylock || ${pkgs.swaylock}/bin/swaylock -f";
      lock         = "${pkgs.procps}/bin/pgrep -x swaylock || ${pkgs.swaylock}/bin/swaylock -f";
    };
  };


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
        { command = "waybar"; }
        { command = "mako"; }
        { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; }
        { command = "wlsunset -l 50.4 -L 30.5"; }
        { command = "foot --server"; }
        { command = "udiskie --tray"; }
        { command = "nm-applet --indicator"; }
      ];
      terminal = "footclient";
      menu     = "wofi --show drun";
      fonts = {
        names = [ "JetBrainsMono Nerd Font" ];
        size  = 12.0;
      };
      output = {
        "DP-2" = {
          mode  = "3840x2160@143.963Hz";
          scale = "1.0";
        };
      };
      window.border = 2;
      colors = {
        focused = {
          border      = "#89b4fa";
          background  = "#89b4fa";
          text        = "#1a1a2e";
          indicator   = "#89b4fa";
          childBorder = "#89b4fa";
        };
        focusedInactive = {
          border      = "#45475a";
          background  = "#1a1a2e";
          text        = "#cdd6f4";
          indicator   = "#45475a";
          childBorder = "#45475a";
        };
        unfocused = {
          border      = "#313244";
          background  = "#1a1a2e";
          text        = "#6c7086";
          indicator   = "#313244";
          childBorder = "#313244";
        };
      };
      bars = [];
      focus.followMouse = false;
      modes = lib.mkOptionDefault {
        layout = {
          "h"         = "layout splith; exec ${pkgs.procps}/bin/pkill -SIGRTMIN+1 waybar";
          "v"         = "layout splitv; exec ${pkgs.procps}/bin/pkill -SIGRTMIN+1 waybar";
          "t"         = "layout tabbed; exec ${pkgs.procps}/bin/pkill -SIGRTMIN+1 waybar";
          "s"         = "layout stacking; exec ${pkgs.procps}/bin/pkill -SIGRTMIN+1 waybar";
          "Tab"       = "exec ${layoutCycle}/bin/layout-cycle";
          "1"         = "resize set width 33 ppt; exec ${pkgs.procps}/bin/pkill -SIGRTMIN+1 waybar";
          "2"         = "resize set width 50 ppt; exec ${pkgs.procps}/bin/pkill -SIGRTMIN+1 waybar";
          "3"         = "resize set width 67 ppt; exec ${pkgs.procps}/bin/pkill -SIGRTMIN+1 waybar";
          "4"         = "resize set width 100 ppt; exec ${pkgs.procps}/bin/pkill -SIGRTMIN+1 waybar";
          "Shift+1"   = "resize set height 33 ppt; exec ${pkgs.procps}/bin/pkill -SIGRTMIN+1 waybar";
          "Shift+2"   = "resize set height 50 ppt; exec ${pkgs.procps}/bin/pkill -SIGRTMIN+1 waybar";
          "Shift+3"   = "resize set height 67 ppt; exec ${pkgs.procps}/bin/pkill -SIGRTMIN+1 waybar";
          "Escape"    = "mode default; exec ${pkgs.procps}/bin/pkill -SIGRTMIN+2 waybar";
          "Return"    = "mode default; exec ${pkgs.procps}/bin/pkill -SIGRTMIN+2 waybar";
        };
      };
      keybindings = let mod = "Mod4"; in {
        "${mod}+Return"       = "exec foot";
        "${mod}+d"            = "exec wofi --show drun";
        "${mod}+q"            = "kill";
        "${mod}+Shift+c"      = "reload";
        "${mod}+Shift+e"      = "exec swaymsg exit";
        "${mod}+ctrl+l"       = "exec loginctl lock-session";
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
        "${mod}+a"            = "mode layout; exec ${pkgs.procps}/bin/pkill -SIGRTMIN+2 waybar";
        "${mod}+Tab"          = "exec ${layoutCycle}/bin/layout-cycle";
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
        "${mod}+p"            = "exec grim -g \"$(slurp)\" - | wl-copy";
        "${mod}+Ctrl+p"       = "exec grim -g \"$(slurp)\" ~/Pictures/$(date +%Y%m%d-%H%M%S).png";
        "--locked XF86AudioMute"        = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "--locked XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
        "--locked XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
        "--locked XF86AudioMicMute"     = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";
        "--locked XF86AudioPlay"        = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
        "--locked XF86AudioNext"        = "exec ${pkgs.playerctl}/bin/playerctl next";
        "--locked XF86AudioPrev"        = "exec ${pkgs.playerctl}/bin/playerctl previous";
      };
    };
    extraConfig = ''
      for_window [app_id="udiskie"] floating enable
      for_window [app_id="Slack" title="^Huddle:"] floating enable
      for_window [app_id=".blueman-manager-wrapped"] floating enable
      for_window [app_id="pavucontrol"] floating enable
      for_window [app_id="nm-connection-editor"] floating enable
      for_window [class="jetbrains-idea" title="Welcome to IntelliJ IDEA"] floating enable
      output * bg #1a1a2e solid_color
      exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
      exec systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    '';
  };
}
