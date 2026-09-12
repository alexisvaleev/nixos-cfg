# SwayNotificationCenter — quick settings / control center + notifications.
{ config, pkgs, lib, ... }:
let
  theme = import ./theme.nix;
  nf = hex: builtins.fromJSON ''"\u${hex}"'';
  ic = {
    wifi      = nf "f1eb";  # nf-fa-wifi
    bluetooth = nf "f294";  # nf-fa-bluetooth
    volume    = nf "f028";  # nf-fa-volume_high
    sun       = nf "f185";  # nf-fa-sun
    lock      = nf "f023";  # nf-fa-lock
    audio     = nf "f025";  # nf-fa-headphones (audio devices)
    power     = nf "f011";  # nf-fa-power_off
    gear      = nf "f013";  # nf-fa-gear
  };

  cfg = {
    ignore-gtk-theme = true;
    positionX = "right";
    positionY = "top";
    control-center-positionX = "right";
    control-center-positionY = "top";
    layer = "overlay";
    control-center-layer = "overlay";
    layer-shell = true;
    layer-shell-cover-screen = true;
    control-center-exclusive-zone = false;
    cssPriority = "user";

    # Place the panel under the waybar and a bit from the right edge.
    control-center-margin-top = 40;
    control-center-margin-right = 12;
    fit-to-screen = false;

    control-center-width = 360;
    control-center-height = -1;
    notification-window-width = 360;
    notification-window-preferred-output = "eDP-1";
    notification-icon-size = 48;
    notification-inline-replies = true;
    notification-body-image-height = 100;
    notification-body-image-width = 200;

    timeout = 8;
    timeout-low = 5;
    timeout-critical = 0;
    relative-timestamps = true;
    transition-time = 200;
    hide-on-clear = false;
    hide-on-action = true;
    text-empty = "No Notifications";
    script-fail-notify = true;
    scripts = {};

    widgets = [
      "title"
      "dnd"
      "buttons-grid"
      "volume"
      "backlight"
      "mpris"
      "notifications"
    ];

    widget-config = {
      title = {
        text = "Control Center";
        clear-all-button = true;
        button-text = "Clear";
      };
      dnd = {
        text = "Do Not Disturb";
      };
      "buttons-grid" = {
        buttons-per-row = 3;
        actions = [
          {
            label = "${ic.wifi}";
            type = "toggle";
            active = true;
            command = "$HOME/.config/swaync/wifi-toggle.sh";
            update-command = "$HOME/.config/swaync/wifi-state.sh";
          }
          {
            label = "${ic.bluetooth}";
            type = "toggle";
            active = false;
            command = "$HOME/.config/swaync/bt-toggle.sh";
            update-command = "$HOME/.config/swaync/bt-state.sh";
          }
          {
            label = "${ic.audio}";
            type = "normal";
            command = "pavucontrol";
            tooltip = "Audio devices";
          }
          {
            label = "${ic.lock}";
            type = "normal";
            command = "hyprlock";
            tooltip = "Lock screen";
          }
          {
            label = "${ic.gear}";
            type = "normal";
            command = "hyprctl reload";
            tooltip = "Reload Hyprland";
          }
          {
            label = "${ic.power}";
            type = "normal";
            command = "$HOME/.config/rofi/powermenu.sh";
            tooltip = "Power menu";
          }
        ];
      };
      volume = {
        label = "${ic.volume}";
        show-per-app = true;
      };
      backlight = {
        label = "${ic.sun}";
        device = "intel_backlight";
      };
      mpris = {
        autohide = true;
        show-album-art = "when-available";
        loop-carousel = true;
      };
      notifications = {};
    };
  };
in
{
  home.packages = with pkgs; [
    swaynotificationcenter
    pavucontrol
    networkmanager
    bluez
  ];

  xdg.configFile."swaync/config.json".text = builtins.toJSON cfg;

  xdg.configFile."swaync/style.css".text = ''
    @import "/home/blessed/.config/theme/colors.css";

    * {
      font-family: "Inter", "Iosevka Nerd Font Propo", "JetBrainsMono Nerd Font", "Noto Sans";
      font-size: 13px;
    }

    .blank-window {
      background: transparent;
    }

    .control-center {
      background: alpha(@bg, 0.9);
      color: @text;
      border-radius: 10px;
      border: 1px solid alpha(@purple, 0.2);
      padding: 8px;
    }

    .control-center .control-center-list {
      background: transparent;
    }

    .widget {
      margin: 6px;
      padding: 10px;
      border-radius: 10px;
      background: alpha(@surface, 0.95);
    }

    .widget-title > label {
      font-weight: bold;
      font-size: 1.2rem;
    }

    .widget-title > button {
      margin-left: 8px;
      border-radius: 10px;
      background: @surface;
      color: @text;
    }

    .widget-title > button:hover {
      background: @surface2;
    }

    .widget-dnd label {
      color: @text;
      font-weight: 500;
    }

    .widget-dnd switch {
      border-radius: 10px;
    }

    .widget-dnd switch:checked {
      background: @purple;
    }

    .widget-buttons-grid {
      padding: 0;
    }

    .widget-buttons-grid > flowbox > flowboxchild > button {
      background: none;
      background-color: @surface;
      color: @text;
      border: 1px solid transparent;
      border-radius: 10px;
      padding: 8px;
      margin: 2px;
      min-width: 0;
      min-height: 0;
      font-size: 18px;
    }

    .widget-buttons-grid > flowbox > flowboxchild > button:hover {
      background-color: @surface2;
      border-color: alpha(@purple, 0.28);
    }

    .widget-buttons-grid > flowbox > flowboxchild > button.toggle:checked {
      background-color: @purple;
      color: @bg;
      border-color: alpha(@purple, 0.55);
    }

    .widget-volume scale trough,
    .widget-backlight scale trough {
      background-color: @surface2;
      border-radius: 999px;
      min-height: 8px;
      margin: 4px 0;
    }

    .widget-volume scale highlight,
    .widget-backlight scale highlight {
      background-color: @purple;
      border-radius: 999px;
    }

    .widget-volume scale slider,
    .widget-backlight scale slider {
      background: @text;
      border-radius: 999px;
      min-width: 14px;
      min-height: 14px;
    }

    .per-app-volume {
      background-color: @surface;
      margin: 8px 0 0;
      border-radius: 10px;
      padding: 8px;
    }

    .widget-mpris .widget-mpris-player {
      border-radius: 10px;
    }

    .notification-row .notification-background .notification {
      border-radius: 10px;
      border: 1px solid alpha(@purple, 0.2);
      background: alpha(@surface, 0.95);
      color: @text;
    }

    .notification-row .notification-background .notification .notification-default-action:hover {
      background: alpha(@surface3, 0.95);
    }

    .close-button {
      background: @surface3;
      color: @text;
      border-radius: 100%;
    }

    .close-button:hover {
      background: @red;
      color: @bg;
    }
  '';

  # Helper scripts for Wi-Fi / Bluetooth toggles (avoids messy inline quoting).
  xdg.configFile."swaync/wifi-toggle.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      if [ "$SWAYNC_TOGGLE_STATE" = "true" ]; then
        nmcli radio wifi on
      else
        nmcli radio wifi off
      fi
    '';
  };

  xdg.configFile."swaync/wifi-state.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      [ "$(nmcli radio wifi)" = "enabled" ] && echo true || echo false
    '';
  };

  xdg.configFile."swaync/bt-toggle.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      if [ "$SWAYNC_TOGGLE_STATE" = "true" ]; then
        bluetoothctl power on
      else
        bluetoothctl power off
      fi
    '';
  };

  xdg.configFile."swaync/bt-state.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      state=$(bluetoothctl show 2>/dev/null | grep Powered | awk '{print $2}')
      [ "$state" = "yes" ] && echo true || echo false
    '';
  };
}
