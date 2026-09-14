{ config, osConfig, pkgs, lib, ... }:

let
  layoutCycle = pkgs.writeShellScriptBin "layout-cycle" ''
    current=$(${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '
      [recurse(.nodes[]?, .floating_nodes[]?) |
        select(.layout | IN("splith", "splitv", "tabbed", "stacking")) |
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

  scratchpadPick = pkgs.writeShellScriptBin "scratchpad-pick" ''
    selected=$(${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '
      [recurse(.nodes[]?, .floating_nodes[]?) |
        select(.scratchpad_state? != null and .scratchpad_state != "none")] |
      .[] | "\(.app_id // .window_properties.class // "?")  \(.name)"
    ' | ${pkgs.wofi}/bin/wofi --dmenu --prompt "Scratchpad")
    [ -z "$selected" ] && exit 0
    title=$(echo "$selected" | sed 's/^[^ ]*  //')
    ${pkgs.sway}/bin/swaymsg "[title=\"$title\"] scratchpad show"
  '';

  # Lock is first so a stray Enter on the empty filter is harmless.
  powerMenu = pkgs.writeShellScriptBin "power-menu" ''
    choice=$(printf '%s\n' Lock Logout Sleep Hibernate Reboot "Power off" | ${pkgs.wofi}/bin/wofi --dmenu --prompt "Power")
    case "$choice" in
      Lock)        ${pkgs.systemd}/bin/loginctl lock-session ;;
      Logout)      ${pkgs.sway}/bin/swaymsg exit ;;
      Sleep)       ${pkgs.systemd}/bin/systemctl suspend ;;
      Hibernate)   ${pkgs.systemd}/bin/systemctl hibernate ;;
      Reboot)      ${pkgs.systemd}/bin/systemctl reboot ;;
      "Power off") ${pkgs.systemd}/bin/systemctl poweroff ;;
    esac
  '';

  screenRec = pkgs.writeShellScriptBin "screen-rec" ''
    if ${pkgs.procps}/bin/pgrep -x wf-recorder >/dev/null; then
      ${pkgs.procps}/bin/pkill -INT -x wf-recorder
      ${pkgs.libnotify}/bin/notify-send "Recording" "Stopped — saved to ~/Videos"
    else
      f="$HOME/Videos/$(${pkgs.coreutils}/bin/date +%Y%m%d-%H%M%S).mp4"
      ${pkgs.libnotify}/bin/notify-send "Recording" "Started → $f"
      ${pkgs.wf-recorder}/bin/wf-recorder -g "$(${pkgs.slurp}/bin/slurp)" -f "$f"
    fi
  '';

  # Restarting the wlr portal backend ends every open screencast session,
  # including one an app forgot to close after "Stop sharing".
  screencastStop = pkgs.writeShellScriptBin "screencast-stop" ''
    ${pkgs.systemd}/bin/systemctl --user restart xdg-desktop-portal-wlr.service
    ${pkgs.libnotify}/bin/notify-send -a screencast "Screen sharing" "Portal restarted - all screencasts stopped"
  '';

  # Toggles the focused output to 2x so a shared screen stays readable for
  # viewers on smaller displays. The mode is untouched, so the panel stays
  # sharp and the capture size does not change mid-share. The previous scale
  # is saved per output and restored on the next press.
  shareScale = pkgs.writeShellScriptBin "share-scale" ''
    read -r name scale <<< "$(${pkgs.sway}/bin/swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | "\(.name) \(.scale)"')"
    [ -z "$name" ] && exit 1
    saved="''${XDG_RUNTIME_DIR:-/tmp}/share-scale.$name"
    if [ -f "$saved" ]; then
      ${pkgs.sway}/bin/swaymsg output "$name" scale "$(cat "$saved")"
      rm -f "$saved"
      ${pkgs.libnotify}/bin/notify-send -a screencast "Share scale" "$name back to normal"
    else
      echo "$scale" > "$saved"
      ${pkgs.sway}/bin/swaymsg output "$name" scale 2
      ${pkgs.libnotify}/bin/notify-send -a screencast "Share scale" "$name at 2x for sharing"
    fi
  '';

  layoutInfo = pkgs.writeShellScriptBin "layout-info" ''
    data=$(${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '
      ([recurse(.nodes[]?, .floating_nodes[]?) |
        select(.layout | IN("splith", "splitv", "tabbed", "stacking")) |
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
  home.packages = with pkgs; [ satty ddcutil wf-recorder layoutCycle layoutInfo layoutHints scratchpadPick screenRec screencastStop shareScale powerMenu ];

  # Session daemons run as user services bound to the graphical session rather
  # than as sway `exec`s: restarted on failure, logged to the journal, and
  # stopped with the session. cliphist, wl-clip-persist and swayr install their
  # own packages.
  services.autotiling.enable      = true;
  services.wl-clip-persist.enable = true;
  services.polkit-gnome.enable    = true;
  services.network-manager-applet.enable = true;
  services.udiskie = {
    enable = true;
    tray   = "always";
  };
  services.cliphist = {
    enable       = true;
    # The untyped text watcher already stores images; the extra image watcher
    # would record each image twice.
    allowImages  = false;
    extraOptions = [ "-max-items" "200" ];
  };
  programs.swayr = {
    enable         = true;
    systemd.enable = true;
  };

  # waybar only hosts StatusNotifierItems, not XEmbed icons. This makes the
  # nm-applet and udiskie services pass --indicator / --appindicator.
  xsession.preferStatusNotifierItems = true;

  # services.cliphist watches only the regular clipboard; this keeps the
  # primary selection in history as well.
  systemd.user.services.cliphist-primary = {
    Unit = {
      Description = "Clipboard history (primary selection)";
      PartOf      = [ config.wayland.systemd.target ];
      After       = [ config.wayland.systemd.target ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --primary --watch ${pkgs.cliphist}/bin/cliphist -max-items 200 store";
      Restart   = "on-failure";
    };
    Install.WantedBy = [ config.wayland.systemd.target ];
  };

  services.swayidle = {
    enable   = true;
    timeouts = [
      { timeout = 300;
         command = "${pkgs.procps}/bin/pgrep -x swaylock || ${pkgs.swaylock}/bin/swaylock -f";
      }
      { timeout = 600;
        command        = "${pkgs.sway}/bin/swaymsg \"output * power off\"";
        resumeCommand  = "${pkgs.sway}/bin/swaymsg \"output * power on\"";
      }
    ];
    events = {
      before-sleep = "${pkgs.procps}/bin/pgrep -x swaylock || ${pkgs.swaylock}/bin/swaylock -f";
      lock         = "${pkgs.procps}/bin/pgrep -x swaylock || ${pkgs.swaylock}/bin/swaylock -f";
    };
  };

  wayland.windowManager.sway = {
    enable = true;
    # This is the sway the session runs (programs.sway.package is null on the
    # NixOS side), so the GTK/GSettings wrapper belongs here.
    wrapperFeatures.gtk = true;
    # mise shims for apps started from sway (IDEs, editors). Interactive
    # shells use `mise activate` instead; the shims resolve the global
    # versions from programs.mise in dev.nix.
    extraSessionCommands = ''
      export PATH="$HOME/.local/share/mise/shims:$PATH"
    '';
    systemd = {
      enable       = true;
      # Sway runs no XDG autostart itself; this starts entries such as
      # blueman-applet through systemd's xdg-desktop-autostart.target.
      xdgAutostart = true;
    };
    config = {
      modifier = "Mod4";
      # Same layout and options as the console and X11 (services.xserver.xkb
      # in modules/system/common.nix), which sway does not read itself.
      input = {
        "*" = {
          xkb_layout  = osConfig.services.xserver.xkb.layout;
          xkb_options = osConfig.services.xserver.xkb.options;
        };
      };
      fonts = {
        names = [ "JetBrainsMono Nerd Font" ];
        size  = 12.0;
      };
      window = {
        border   = 2;
        # pixel borders; tabbed and stacked containers still show titles.
        titlebar = false;
      };
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
        "${mod}+Return"      = "exec ${pkgs.ghostty}/bin/ghostty";
        "${mod}+space"       = "exec ${pkgs.wofi}/bin/wofi --show drun";
        "${mod}+q"           = "kill";
        "${mod}+Shift+c"     = "reload";
        "${mod}+Shift+e"     = "exec ${powerMenu}/bin/power-menu";
        "${mod}+ctrl+l"      = "exec loginctl lock-session";
        "${mod}+h"           = "focus left";
        "${mod}+j"           = "focus down";
        "${mod}+k"           = "focus up";
        "${mod}+l"           = "focus right";
        "Alt+Tab"            = "exec ${pkgs.swayr}/bin/swayr next-window current-workspace";
        "Alt+Shift+Tab"      = "exec ${pkgs.swayr}/bin/swayr prev-window current-workspace";
        "${mod}+Shift+h"     = "move left";
        "${mod}+Shift+j"     = "move down";
        "${mod}+Shift+k"     = "move up";
        "${mod}+Shift+l"     = "move right";
        "${mod}+a"           = "mode layout; exec ${pkgs.procps}/bin/pkill -SIGRTMIN+2 waybar";
        "${mod}+Tab"         = "exec ${layoutCycle}/bin/layout-cycle";
        "${mod}+f"           = "fullscreen toggle";
        "${mod}+n"           = "exec ${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
        "${mod}+Shift+n"     = "exec ${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
        "${mod}+r"           = "mode resize";
        "${mod}+Shift+r"     = "exec ${screenRec}/bin/screen-rec";
        "${mod}+Shift+s"     = "exec ${screencastStop}/bin/screencast-stop";
        "${mod}+Ctrl+s"      = "exec ${shareScale}/bin/share-scale";
        "${mod}+minus"       = "scratchpad show";
        "${mod}+ctrl+minus"  = "exec ${scratchpadPick}/bin/scratchpad-pick";
        "${mod}+Shift+minus" = "move scratchpad";
        "${mod}+Shift+f"     = "floating toggle";
        "${mod}+1"           = "workspace number 1";
        "${mod}+2"           = "workspace number 2";
        "${mod}+3"           = "workspace number 3";
        "${mod}+4"           = "workspace number 4";
        "${mod}+5"           = "workspace number 5";
        "${mod}+6"           = "workspace number 6";
        "${mod}+7"           = "workspace number 7";
        "${mod}+8"           = "workspace number 8";
        "${mod}+9"           = "workspace number 9";
        "${mod}+0"           = "workspace number 10";
        "${mod}+Shift+1"     = "move container to workspace number 1";
        "${mod}+Shift+2"     = "move container to workspace number 2";
        "${mod}+Shift+3"     = "move container to workspace number 3";
        "${mod}+Shift+4"     = "move container to workspace number 4";
        "${mod}+Shift+5"     = "move container to workspace number 5";
        "${mod}+Shift+6"     = "move container to workspace number 6";
        "${mod}+Shift+7"     = "move container to workspace number 7";
        "${mod}+Shift+8"     = "move container to workspace number 8";
        "${mod}+Shift+9"     = "move container to workspace number 9";
        "${mod}+Shift+0"     = "move container to workspace number 10";
        "${mod}+Shift+v"     = "exec ${pkgs.cliphist}/bin/cliphist list | ${pkgs.wofi}/bin/wofi --dmenu | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy";
        "${mod}+p"           = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.satty}/bin/satty --filename - --output-filename ~/Pictures/$(date +%Y%m%d-%H%M%S).png --early-exit --copy-command ${pkgs.wl-clipboard}/bin/wl-copy";
        "${mod}+Shift+p"     = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.wl-clipboard}/bin/wl-copy";
        "${mod}+Ctrl+p"      = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" ~/Pictures/$(date +%Y%m%d-%H%M%S).png";
        "--locked XF86MonBrightnessUp"   = "exec ${pkgs.ddcutil}/bin/ddcutil setvcp 10 + 10";
        "--locked XF86MonBrightnessDown" = "exec ${pkgs.ddcutil}/bin/ddcutil setvcp 10 - 10";
        "--locked XF86AudioMute"        = "exec ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        "--locked XF86AudioLowerVolume" = "exec ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        "--locked XF86AudioRaiseVolume" = "exec ${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+";
        "--locked XF86AudioMicMute"     = "exec ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        "--locked XF86AudioPlay"        = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
        "--locked XF86AudioNext"        = "exec ${pkgs.playerctl}/bin/playerctl next";
        "--locked XF86AudioPrev"        = "exec ${pkgs.playerctl}/bin/playerctl previous";
      };
    };
    extraConfig = ''
      for_window [all] inhibit_idle fullscreen
      for_window [app_id="udiskie"] floating enable
      for_window [app_id="Slack" title="^Huddle:"] floating enable
      for_window [app_id=".blueman-manager-wrapped"] floating enable
      for_window [app_id="pavucontrol"] floating enable
      for_window [app_id="nm-connection-editor"] floating enable
      for_window [class="jetbrains-idea" title="Welcome to IntelliJ IDEA"] floating enable
      output * bg #1a1a2e solid_color
    '';
  };
}
