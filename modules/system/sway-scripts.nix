{ pkgs, lib, ... }:

# Helper commands for the sway session, installed on PATH. The sway config
# that binds them (and the window-snap daemon user unit) lives in the user's
# dotfiles.
let
  # Magnet-style placement; behaviour is documented in window-snap.py. The
  # same binary also runs as a daemon (`window-snap --daemon`) to apply tiled
  # snaps made on a window that was alone on its workspace.
  windowSnap = pkgs.writers.writePython3Bin "window-snap" {
    libraries = [ pkgs.python3Packages.i3ipc ];
    flakeIgnore = [ "E501" ];
  } (lib.replaceStrings [ "@notify_send@" ] [ "${pkgs.libnotify}/bin/notify-send" ]
      (builtins.readFile ./window-snap.py));

  # Searchable key binding help ($mod+/); behaviour is documented in key-help.py.
  keyHelp = pkgs.writers.writePython3Bin "key-help" {
    flakeIgnore = [ "E501" ];
  } (lib.replaceStrings [ "@swaymsg@" "@wofi@" ]
      [ "${pkgs.sway}/bin/swaymsg" "${pkgs.wofi}/bin/wofi" ]
      (builtins.readFile ./key-help.py));

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
in
{
  environment.systemPackages = [
    windowSnap
    keyHelp
    scratchpadPick
    powerMenu
    screenRec
    screencastStop
    shareScale
  ];
}
