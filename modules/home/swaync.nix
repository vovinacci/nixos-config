{ config, pkgs, ... }: {
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      control-center-width  = 380;
      control-center-margin-top    = 8;
      control-center-margin-bottom = 8;
      control-center-margin-right  = 8;
      control-center-margin-left   = 8;
      notification-window-width = 380;
      notification-icon-size    = 48;
      notification-body-image-height = 100;
      notification-body-image-width  = 200;
      timeout          = 5;
      timeout-low      = 3;
      timeout-critical = 0;
      fit-to-screen    = true;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time  = 200;
      hide-on-clear         = false;
      hide-on-action        = true;
      widgets = [ "title" "dnd" "notifications" ];
      widget-config = {
        title = {
          text  = "Notifications";
          clear-all-button = true;
          button-text = "Clear All";
        };
        dnd.text = "Do Not Disturb";
      };
    };
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 14px;
      }
      .control-center {
        background: #1a1a2e;
        border: 1px solid #313244;
        border-radius: 8px;
        color: #cdd6f4;
      }
      .notification-row .notification-background {
        background: #181825;
        border: 1px solid #313244;
        border-radius: 6px;
        margin: 4px;
      }
      .notification-row .notification-background .notification.critical {
        border: 1px solid #f38ba8;
      }
      .notification-row .notification-background .notification .notification-content {
        color: #cdd6f4;
        padding: 8px;
      }
      .notification-row .notification-background .close-button {
        background: #313244;
        color: #cdd6f4;
        border-radius: 6px;
      }
      .notification-row .notification-background .close-button:hover {
        background: #f38ba8;
        color: #1a1a2e;
      }
      .control-center .widget-title { color: #cdd6f4; }
      .control-center .widget-title > button {
        background: #313244;
        color: #cdd6f4;
        border-radius: 6px;
      }
      .control-center .widget-title > button:hover { background: #89b4fa; color: #1a1a2e; }
      .widget-dnd { color: #cdd6f4; }
      .widget-dnd > switch {
        background: #313244;
        border-radius: 12px;
      }
      .widget-dnd > switch:checked { background: #89b4fa; }
      .floating-notifications.background .notification-background {
        background: #1a1a2e;
        border: 1px solid #313244;
        border-radius: 8px;
      }
    '';
  };
}
