{ config, pkgs, ... }: {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    # Self-contained, on the repo palette (see CONTRIBUTING.md). Replaces
    # waybar's upstream stylesheet, which is Roboto/FontAwesome on a grey
    # translucent bar and matched nothing else on this desktop.
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 16px;
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      window#waybar {
        background-color: #1a1a2e;
        color: #cdd6f4;
      }

      window#waybar.hidden {
        opacity: 0.2;
      }

      #workspaces,
      #mode,
      #custom-layout,
      #custom-layout-hints,
      #mpris,
      #clock,
      #privacy,
      #idle_inhibitor,
      #disk,
      #temperature,
      #cpu,
      #memory,
      #bluetooth,
      #pulseaudio,
      #network,
      #language,
      #tray,
      #custom-notification,
      #custom-sleep,
      #custom-lock {
        padding: 0 10px;
        color: #cdd6f4;
        background-color: transparent;
      }

      #workspaces {
        padding: 0 4px;
      }

      #workspaces button {
        padding: 0 8px;
        margin: 6px 2px;
        color: #6c7086;
        background-color: #181825;
        border-radius: 6px;
      }

      #workspaces button:hover {
        background-color: #313244;
        color: #cdd6f4;
      }

      /* Ordered least- to most-important: a focused workspace also carries
         .visible, and these selectors have equal specificity, so whichever
         comes last wins. .focused must therefore follow .visible. */
      #workspaces button.visible {
        color: #bac2de;
      }

      #workspaces button.focused {
        background-color: #89b4fa;
        color: #1a1a2e;
        font-weight: bold;
      }

      #workspaces button.urgent {
        background-color: #f38ba8;
        color: #1a1a2e;
      }

      #mode {
        color: #fab387;
        font-weight: bold;
      }

      #custom-layout {
        color: #89b4fa;
      }

      #custom-layout-hints {
        color: #bac2de;
        font-style: italic;
      }

      #mpris {
        color: #a6e3a1;
      }

      #clock {
        color: #cdd6f4;
        font-weight: bold;
      }

      #cpu {
        color: #a6e3a1;
      }

      #memory {
        color: #fab387;
      }

      #disk {
        color: #bac2de;
      }

      #temperature {
        color: #a6e3a1;
      }

      #temperature.critical {
        color: #f38ba8;
        font-weight: bold;
      }

      #bluetooth {
        color: #89b4fa;
      }

      #bluetooth.disabled,
      #bluetooth.off {
        color: #6c7086;
      }

      #pulseaudio {
        color: #89b4fa;
      }

      #pulseaudio.muted {
        color: #6c7086;
      }

      #network {
        color: #89b4fa;
      }

      #network.disconnected {
        color: #f38ba8;
      }

      #language {
        color: #bac2de;
      }

      #privacy {
        color: #f38ba8;
      }

      #idle_inhibitor {
        color: #6c7086;
      }

      #idle_inhibitor.activated {
        color: #fab387;
      }

      #custom-notification {
        color: #cdd6f4;
      }

      #custom-sleep {
        color: #bac2de;
      }

      #custom-lock {
        color: #f38ba8;
      }

      #tray {
        padding: 0 8px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
      }
    '';
    settings.mainBar = {
      layer   = "top";
      height  = 45;
      spacing = 15;

      modules-left   = [ "sway/workspaces" "sway/mode" "custom/layout" "custom/layout-hints" "mpris" ];
      modules-center = [ "clock" ];
      modules-right  = [ "privacy" "idle_inhibitor" "disk" "temperature" "cpu" "memory" "bluetooth" "pulseaudio" "network" "sway/language" "tray" "custom/notification" "custom/sleep" "custom/lock" ];

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
        exec     = "layout-info";
        signal   = 1;
        interval = 5;
        format   = "{}";
        tooltip  = false;
      };

      "custom/layout-hints" = {
        exec    = "layout-hints";
        signal  = 2;
        format  = "{}";
        tooltip = false;
      };

      clock = {
        format     = "{:%a %d %b  %H:%M}";
        tooltip    = false;
      };

      pulseaudio = {
        format        = "{icon} {volume}%";
        format-muted  = "󰝟";
        format-icons  = { default = [ "󰕿" "󰖀" "󰕾" ]; };
        on-click      = "${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
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
        on-click = "setsid bash -c 'sleep 0.2; systemctl suspend'";
        tooltip  = false;
      };

      "custom/lock" = {
        format   = "⏻ ";
        on-click = "setsid bash -c 'sleep 0.2; loginctl lock-session'";
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
        on-click        = "${pkgs.blueman}/bin/blueman-manager";
        tooltip-format  = "{controller_alias} · {controller_address}\n{num_connections} connected";
        tooltip-format-connected = "{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias} · {device_address}";
      };

      "sway/language" = {
        format   = "⌨ {short}";
        tooltip  = false;
        on-click = "${pkgs.sway}/bin/swaymsg input '*' xkb_switch_layout next";
      };

      disk = {
        format   = "󰋊 {percentage_used}%";
        path     = "/persist";
        interval = 30;
        tooltip-format = "{used} / {total}";
      };

      privacy = {
        icon-spacing = 4;
        icon-size    = 22;
        transition-duration = 250;
        modules = [
          { type = "screenshare"; tooltip = true; tooltip-icon-size = 40; }
          { type = "audio-in";    tooltip = true; tooltip-icon-size = 40; }
        ];
      };

      cpu = {
        format = "󰘚 {usage}%";
      };

      memory = {
        format = "󰍛 {percentage}%";
      };

      tray = {
        spacing = 15;
      };

      "custom/notification" = {
        tooltip      = false;
        format       = "{icon}";
        format-icons = {
          notification     = "󱅫 ";
          none             = "󰂚 ";
          dnd-notification = "󰂛 ";
          dnd-none         = "󰂛 ";
          inhibited-notification = "󱅫 ";
          inhibited-none   = "󰂚 ";
          dnd-inhibited-notification = "󰂛 ";
          dnd-inhibited-none = "󰂛 ";
        };
        return-type    = "json";
        exec           = "${pkgs.swaynotificationcenter}/bin/swaync-client -swb";
        on-click       = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
        on-click-right = "${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
        escape         = true;
      };
    };
  };
}
