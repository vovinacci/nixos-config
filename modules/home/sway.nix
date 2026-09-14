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

  # Key bindings, each with its description, in one place. Sway's
  # keybindings, the window mode, and the key help ($mod+/) are all generated
  # from these lists, so a binding cannot exist without a description and the
  # help cannot drift from the config (the model of niri's hotkey overlay and
  # which-key).
  mod  = "Mod4";
  bind = key: desc: cmd: { inherit key desc cmd; };
  snap = action: "mode default; exec ${windowSnap}/bin/window-snap ${action}";
  shot = "${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\"";
  pic  = "~/Pictures/$(date +%Y%m%d-%H%M%S).png";

  keyBindings = [
    (bind "${mod}+Return"      "Terminal (Ghostty)"                    "exec ${pkgs.ghostty}/bin/ghostty")
    (bind "${mod}+space"       "App launcher"                          "exec ${pkgs.wofi}/bin/wofi --show drun")
    (bind "${mod}+q"           "Close window"                          "kill")
    (bind "${mod}+Shift+c"     "Reload sway config"                    "reload")
    (bind "${mod}+Shift+e"     "Power menu: lock, log out, sleep, reboot, power off" "exec ${powerMenu}/bin/power-menu")
    (bind "${mod}+Ctrl+l"      "Lock screen"                           "exec loginctl lock-session")
    (bind "${mod}+h"           "Focus left"                            "focus left")
    (bind "${mod}+j"           "Focus down"                            "focus down")
    (bind "${mod}+k"           "Focus up"                              "focus up")
    (bind "${mod}+l"           "Focus right"                           "focus right")
    (bind "Alt+Tab"            "Next window on this workspace"         "exec ${pkgs.swayr}/bin/swayr next-window current-workspace")
    (bind "Alt+Shift+Tab"      "Previous window on this workspace"     "exec ${pkgs.swayr}/bin/swayr prev-window current-workspace")
    (bind "${mod}+Shift+h"     "Move window left"                      "move left")
    (bind "${mod}+Shift+j"     "Move window down"                      "move down")
    (bind "${mod}+Shift+k"     "Move window up"                        "move up")
    (bind "${mod}+Shift+l"     "Move window right"                     "move right")
    (bind "${mod}+w"           "Window mode: snap halves, thirds, quarters; tabs, stack, split" "mode \"${windowMode}\"")
    (bind "${mod}+f"           "Fullscreen"                            "fullscreen toggle")
    (bind "${mod}+Shift+f"     "Float or tile window"                  "floating toggle")
    # focus left/right never crosses between the tiling and floating layers;
    # this is the only keyboard way from one to the other.
    (bind "${mod}+Shift+space" "Focus between tiled and floating windows" "focus mode_toggle")
    (bind "${mod}+r"           "Resize mode: h/j/k/l or arrows, Esc to leave" "mode resize")
    (bind "${mod}+n"           "Notification centre"                   "exec ${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw")
    (bind "${mod}+Shift+n"     "Do not disturb"                        "exec ${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw")
    (bind "${mod}+minus"       "Scratchpad: show or cycle"             "scratchpad show")
    (bind "${mod}+Ctrl+minus"  "Scratchpad: pick a window"             "exec ${scratchpadPick}/bin/scratchpad-pick")
    (bind "${mod}+Shift+minus" "Scratchpad: send window there"         "move scratchpad")
    (bind "${mod}+Shift+v"     "Clipboard history"                     "exec ${pkgs.cliphist}/bin/cliphist list | ${pkgs.wofi}/bin/wofi --dmenu | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy")
    (bind "${mod}+p"           "Screenshot region: annotate, save or copy (satty)" "exec ${shot} - | ${pkgs.satty}/bin/satty --filename - --output-filename ${pic} --early-exit --copy-command ${pkgs.wl-clipboard}/bin/wl-copy")
    (bind "${mod}+Shift+p"     "Screenshot region to clipboard"        "exec ${shot} - | ${pkgs.wl-clipboard}/bin/wl-copy")
    (bind "${mod}+Ctrl+p"      "Screenshot region to ~/Pictures"       "exec ${shot} ${pic}")
    (bind "${mod}+Shift+r"     "Screen recording: start or stop (region, ~/Videos)" "exec ${screenRec}/bin/screen-rec")
    (bind "${mod}+Shift+s"     "Stop all screen sharing"               "exec ${screencastStop}/bin/screencast-stop")
    (bind "${mod}+Ctrl+s"      "Screen-share scale: toggle 2x"         "exec ${shareScale}/bin/share-scale")
    (bind "--locked XF86MonBrightnessUp"   "Brightness up"              "exec ${pkgs.ddcutil}/bin/ddcutil setvcp 10 + 10")
    (bind "--locked XF86MonBrightnessDown" "Brightness down"            "exec ${pkgs.ddcutil}/bin/ddcutil setvcp 10 - 10")
    (bind "--locked XF86AudioMute"         "Mute audio"                 "exec ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
    (bind "--locked XF86AudioLowerVolume"  "Volume down"                "exec ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
    (bind "--locked XF86AudioRaiseVolume"  "Volume up"                  "exec ${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+")
    (bind "--locked XF86AudioMicMute"      "Mute microphone"            "exec ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
    (bind "--locked XF86AudioPlay"         "Play or pause media"        "exec ${pkgs.playerctl}/bin/playerctl play-pause")
    (bind "--locked XF86AudioNext"         "Next track"                 "exec ${pkgs.playerctl}/bin/playerctl next")
    (bind "--locked XF86AudioPrev"         "Previous track"             "exec ${pkgs.playerctl}/bin/playerctl previous")
  ] ++ lib.concatMap (n:
    let ws = toString n; key = if n == 10 then "0" else ws; in [
      (bind "${mod}+${key}"       "Go to workspace ${ws}"          "workspace number ${ws}")
      (bind "${mod}+Shift+${key}" "Move window to workspace ${ws}" "move container to workspace number ${ws}")
    ]) (lib.range 1 10);

  # One key after $mod+w, then back to the default mode.
  windowModeBindings = [
    (bind "h"         "Snap: left half"            (snap "left"))
    (bind "l"         "Snap: right half"           (snap "right"))
    (bind "k"         "Snap: top half"             (snap "top"))
    (bind "j"         "Snap: bottom half"          (snap "bottom"))
    (bind "y"         "Snap: top-left quarter"     (snap "top-left"))
    (bind "u"         "Snap: top-right quarter"    (snap "top-right"))
    (bind "b"         "Snap: bottom-left quarter"  (snap "bottom-left"))
    (bind "n"         "Snap: bottom-right quarter" (snap "bottom-right"))
    (bind "1"         "Snap: left third"           (snap "left-third"))
    (bind "2"         "Snap: centre third"         (snap "center-third"))
    (bind "3"         "Snap: right third"          (snap "right-third"))
    (bind "Shift+1"   "Snap: left two-thirds"      (snap "left-two-thirds"))
    (bind "Shift+3"   "Snap: right two-thirds"     (snap "right-two-thirds"))
    (bind "f"         "Snap: maximise"             (snap "maximize"))
    (bind "Return"    "Snap: maximise"             (snap "maximize"))
    (bind "c"         "Snap: centre"               (snap "center"))
    (bind "r"         "Snap: restore"              (snap "restore"))
    (bind "BackSpace" "Snap: restore"              (snap "restore"))
    (bind "t"         "Layout: tabbed"             "mode default; layout tabbed")
    (bind "s"         "Layout: stacking"           "mode default; layout stacking")
    (bind "e"         "Layout: toggle split direction" "mode default; layout toggle split")
    (bind "Escape"    "Leave window mode"          "mode default")
  ];

  toBindings = bs:
    let keys = map (b: b.key) bs; in
    assert lib.assertMsg (lib.length (lib.unique keys) == lib.length keys)
      "sway.nix: duplicate key in a binding list";
    lib.listToAttrs (map (b: lib.nameValuePair b.key b.cmd) bs);

  # Rows of the key help: label, description, command. The help binding
  # itself is not listed (its command would have to contain this file).
  prettyKey = lib.replaceStrings [ "--locked " "--to-code " "Mod4" ] [ "" "" "Super" ];
  keyHelpData = pkgs.writeText "sway-key-help.tsv" (lib.concatMapStrings
    (r: "${r.label}\t${r.desc}\t${r.cmd}\n")
    (map (b: b // { label = prettyKey b.key; }) keyBindings
      ++ map (b: b // { label = "Super+W, ${b.key}"; })
           (lib.filter (b: b.cmd != "mode default") windowModeBindings)));

  # The launcher's own style plus a monospace font, so the key column lines up.
  keyHelpStyle = pkgs.writeText "key-help.css" (config.xdg.configFile."wofi/style.css".text + ''
    #text { font-family: "JetBrainsMono Nerd Font", monospace; }
  '');

  # Fuzzy search over keys and descriptions; Enter runs the selected binding.
  keyHelp = pkgs.writeShellScriptBin "key-help" ''
    declare -A command
    rows=()
    while IFS=$'\t' read -r label desc cmd; do
      row=$(printf '%-26s %s' "$label" "$desc")
      rows+=("$row")
      command["$row"]=$cmd
    done < ${keyHelpData}

    choice=$(printf '%s\n' "''${rows[@]}" | ${pkgs.wofi}/bin/wofi --dmenu \
      --prompt "Key or action" --insensitive --matching fuzzy \
      --cache-file /dev/null --width 50% --lines 24 --style ${keyHelpStyle}) || exit 0
    [ -n "''${command[$choice]:-}" ] && ${pkgs.sway}/bin/swaymsg -q -- "''${command[$choice]}"
  '';
  helpBinding = bind "--to-code ${mod}+slash" "Key help" "exec ${keyHelp}/bin/key-help";
in
{
  home.packages = with pkgs; [ satty ddcutil wf-recorder windowSnap keyHelp scratchpadPick screenRec screencastStop shareScale powerMenu ];

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
      # Generated from the binding lists at the top of this file.
      modes = lib.mkOptionDefault {
        ${windowMode} = toBindings windowModeBindings;
      };
      keybindings = toBindings (keyBindings ++ [ helpBinding ]);
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
