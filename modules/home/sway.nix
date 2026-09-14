{ config, osConfig, pkgs, lib, ... }:

let
  # Magnet-style placement; behaviour is documented in window-snap.py. The
  # same binary runs as a daemon (systemd.user.services.window-snap below) to
  # apply tiled snaps made on a window that was alone on its workspace.
  windowSnap = pkgs.writers.writePython3Bin "window-snap" {
    libraries = [ pkgs.python3Packages.i3ipc ];
    flakeIgnore = [ "E501" ];
  } (lib.replaceStrings [ "@notify_send@" ] [ "${pkgs.libnotify}/bin/notify-send" ]
      (builtins.readFile ./window-snap.py));

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

  # The mode's name is its key map: waybar's sway/mode module displays it
  # while the mode is active.
  windowMode = "window: h/l/k/j half · y/u/b/n quarter · 1/2/3 third · ⇧1/⇧3 two-thirds · f max · c center · r restore · t tabs · s stack · e split";
in
{
  home.packages = with pkgs; [ satty ddcutil wf-recorder windowSnap scratchpadPick screenRec screencastStop shareScale powerMenu ];

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

  systemd.user.services.window-snap = {
    Unit = {
      Description = "Apply pending sway window snaps when windows open";
      PartOf      = [ config.wayland.systemd.target ];
      After       = [ config.wayland.systemd.target ];
    };
    Service = {
      ExecStart = "${windowSnap}/bin/window-snap --daemon";
      Restart   = "on-failure";
    };
    Install.WantedBy = [ config.wayland.systemd.target ];
  };

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
      # One key after $mod+w, then back to the default mode.
      modes = lib.mkOptionDefault {
        ${windowMode} = let snap = a: "mode default; exec ${windowSnap}/bin/window-snap ${a}"; in {
          "h"         = snap "left";
          "l"         = snap "right";
          "k"         = snap "top";
          "j"         = snap "bottom";
          "y"         = snap "top-left";
          "u"         = snap "top-right";
          "b"         = snap "bottom-left";
          "n"         = snap "bottom-right";
          "1"         = snap "left-third";
          "2"         = snap "center-third";
          "3"         = snap "right-third";
          "Shift+1"   = snap "left-two-thirds";
          "Shift+3"   = snap "right-two-thirds";
          "f"         = snap "maximize";
          "Return"    = snap "maximize";
          "c"         = snap "center";
          "r"         = snap "restore";
          "BackSpace" = snap "restore";
          "t"         = "mode default; layout tabbed";
          "s"         = "mode default; layout stacking";
          "e"         = "mode default; layout toggle split";
          "Escape"    = "mode default";
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
        "${mod}+w"           = "mode \"${windowMode}\"";
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
        # focus left/right never crosses between the tiling and floating
        # layers; this is the only keyboard way from one to the other.
        "${mod}+Shift+space" = "focus mode_toggle";
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

      # Criteria are regexes matched anywhere in the value, so they are
      # anchored: an app changing its ID should stop matching, not match by
      # accident (pavucontrol 6 is org.pulseaudio.pavucontrol, not pavucontrol).
      # Utility windows open at a readable size in the middle of the screen.
      for_window [app_id="^udiskie$"] floating enable
      for_window [app_id="^Slack$" title="^Huddle:"] floating enable
      for_window [app_id="^\.blueman-manager-wrapped$"] floating enable, resize set 40 ppt 50 ppt, move position center
      for_window [app_id="^org\.pulseaudio\.pavucontrol$"] floating enable, resize set 40 ppt 50 ppt, move position center
      for_window [app_id="^nm-connection-editor$"] floating enable, resize set 40 ppt 50 ppt, move position center
      # IDEA runs under XWayland (class) or natively (app_id), depending on
      # its awt.toolkit setting.
      for_window [class="^jetbrains-idea$" title="^Welcome to IntelliJ IDEA$"] floating enable
      for_window [app_id="^jetbrains-idea$" title="^Welcome to IntelliJ IDEA$"] floating enable
      # Picture-in-picture video stays on top of every workspace.
      for_window [app_id="^firefox$" title="^Picture-in-Picture$"] floating enable, sticky enable

      output * bg #1a1a2e solid_color
    '';
  };
}
