{ config, pkgs, ... }: {
  programs.waybar = {
    enable = true;
    settings.mainBar = {
      layer   = "top";
      height  = 32;
      spacing = 8;

      modules-left   = [ "sway/workspaces" "sway/mode" "custom/layout" "mpris" ];
      modules-center = [ "clock" ];
      modules-right  = [ "privacy" "idle_inhibitor" "disk" "temperature" "cpu" "memory" "bluetooth" "pulseaudio" "network" "sway/language" "tray" "custom/sleep" "custom/lock" ];

      "sway/workspaces" = {
        disable-scroll = true;
        all-outputs    = false;
      };

      mpris = {
        format = "{status_icon} {artist} \"{title}\"";
        status-icons = { playing = "󰓇 "; paused = "⏸"; stopped = "■"; };
        max-length = 50;
        on-click = "${pkgs.sway}/bin/swaymsg '[app_id=\"spotify\"] focus'";
        on-click-middle = "${pkgs.playerctl}/bin/playerctl play-pause";
        tooltip = false;
      };

      "custom/layout" = {
        exec     = ''swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '[recurse(.nodes[]?,.floating_nodes[]?) | select(((.nodes//[]) + (.floating_nodes//[])) | map(select(.focused)) | length > 0)] | last | .layout' | sed 's/splith/[H]/;s/splitv/[V]/;s/tabbed/[T]/;s/stacking/[S]/'  '';
        interval = 1;
        format   = "{}";
        tooltip  = false;
      };

      clock = {
        format     = "{:%a %d %b  %H:%M}";
        tooltip    = false;
      };

      pulseaudio = {
        format        = "{icon} {volume}%";
        format-muted  = "󰝟";
        format-icons  = { default = [ "󰕿" "󰖀" "󰕾" ]; };
        on-click      = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
      };

      network = {
        format-ethernet  = "󰈀 {ipaddr}";
        format-wifi      = "󰤨 {essid}";
        format-linked    = "󰈀 (no IP)";
        format-disconnected = "󰤭";
        tooltip          = false;
      };

      "custom/sleep" = {
        format   = "⏾ ";
        on-click = "systemctl suspend";
        tooltip  = false;
      };

      "custom/lock" = {
        format   = "⏻ ";
        on-click = "loginctl lock-session";
        tooltip  = false;
      };

      "idle_inhibitor" = {
        format = "idle: {icon}";
        format-icons = {
          activated   = " ";
          deactivated = " ";
        };
      };

      temperature = {
        critical-threshold = 85;
        format        = "󰔏 {temperatureC}°C";
        format-critical = "󰸁 {temperatureC}°C";
      };

      bluetooth = {
        format          = "󰂯 {status}";
        format-connected = "󰂱 {device_alias}";
        format-disabled = "";
        on-click        = "blueman-manager";
        tooltip-format  = "{controller_alias} · {controller_address}\n{num_connections} connected";
        tooltip-format-connected = "{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias} · {device_address}";
      };

      "sway/language" = {
        format   = "⌨ {short}";
        tooltip  = false;
        on-click = "swaymsg input '*' xkb_switch_layout next";
      };

      disk = {
        format   = "󰋊 {percentage_used}%";
        path     = "/persist";
        interval = 30;
        tooltip-format = "{used} / {total}";
      };

      privacy = {
        icon-spacing = 4;
        icon-size    = 14;
        transition-duration = 250;
        modules = [
          { type = "screenshare"; tooltip = true; tooltip-icon-size = 24; }
          { type = "audio-in";   tooltip = true; tooltip-icon-size = 24; }
        ];
      };

      cpu = {
        format   = "󰘚 {usage}%";
        interval = 5;
      };

      memory = {
        format   = "󰍛 {percentage}%";
        interval = 10;
      };

      tray = {
        spacing = 8;
      };
    };
  };
}
