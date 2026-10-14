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
    moon      = nf "f186";  # nf-fa-moon
    coffee    = nf "f0f4";  # nf-fa-coffee
    netmenu   = nf "f6ff";  # nf-fa-network_wired
    proxy     = nf "f132";  # nf-fa-shield
    record    = nf "f192";  # nf-fa-circle_dot (record indicator)
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
          # row 1 — connectivity
          {
            label = "${ic.proxy}";
            type = "toggle";
            active = false;
            command = "$HOME/.config/swaync/proxy-toggle.sh";
            update-command = "pgrep -x v2rayN >/dev/null && echo true || echo false";
            tooltip = "Proxy (v2rayN)";
          }
          {
            label = "${ic.wifi}";
            type = "toggle";
            active = true;
            command = "$HOME/.config/swaync/wifi-toggle.sh";
            update-command = "$HOME/.config/swaync/wifi-state.sh";
            tooltip = "Wi-Fi";
          }
          {
            label = "${ic.netmenu}";
            type = "normal";
            command = "networkmanager_dmenu";
            tooltip = "Network menu";
          }
          # row 2 — session behaviour
          {
            label = "${ic.moon}";
            type = "toggle";
            active = false;
            command = "$HOME/.config/hypr/scripts/nightlight.sh";
            update-command = "hyprctl getoption decoration:screen_shader | grep -q nightlight && echo true || echo false";
            tooltip = "Night light";
          }
          {
            label = "${ic.coffee}";
            type = "toggle";
            active = false;
            command = "$HOME/.config/hypr/scripts/caffeine.sh toggle";
            update-command = "pgrep -f why=caffeine >/dev/null && echo true || echo false";
            tooltip = "Caffeine";
          }
          {
            label = "${ic.record}";
            type = "toggle";
            active = false;
            command = "$HOME/.config/hypr/scripts/record.sh";
            update-command = "pgrep -x wf-recorder >/dev/null && echo true || echo false";
            tooltip = "Screen record";
          }
          # row 3 — devices & session
          {
            label = "${ic.bluetooth}";
            type = "normal";
            command = "$HOME/.config/swaync/bt-menu.sh";
            tooltip = "Bluetooth devices";
          }
          {
            label = "${ic.lock}";
            type = "normal";
            command = "hyprlock";
            tooltip = "Lock screen";
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
        # No fixed device — pick the first available so the same config
        # works on laptop panels, ddcci (DDC/CI) external monitors, etc.
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
      border-radius: 12px;
      border: 1px solid alpha(@purple, 0.2);
      padding: 8px;
    }

    .control-center .control-center-list {
      background: transparent;
    }

    .widget {
      margin: 6px;
      padding: 10px;
      border-radius: 12px;
      background: alpha(@surface, 0.95);
    }

    .widget-title > label {
      font-weight: bold;
      font-size: 1.2rem;
    }

    .widget-title > button {
      margin-left: 8px;
      border-radius: 12px;
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
      border-radius: 12px;
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
      border-radius: 12px;
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
      border-radius: 12px;
      padding: 8px;
    }

    .widget-mpris .widget-mpris-player {
      border-radius: 12px;
    }

    .notification-row .notification-background .notification {
      border-radius: 12px;
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

  # Proxy toggle — v2rayN as a whole. setsid + fd detach so the GUI
  # process can't hold a pipe open and hang SwayNC's click handler
  # (same failure mode the caffeine/nightlight scripts already avoid).
  xdg.configFile."swaync/proxy-toggle.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      if [ "$SWAYNC_TOGGLE_STATE" = "true" ]; then
        pgrep -x v2rayN >/dev/null || \
          setsid ${pkgs.v2rayn}/bin/v2rayN </dev/null >/dev/null 2>&1 &
      else
        pkill -x v2rayN 2>/dev/null || true
      fi
    '';
  };

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
      # `nmcli radio wifi` says "enabled" even with no wireless adapter
      # at all — report on only when real wifi hardware exists too.
      if nmcli -t -f TYPE device status | grep -qx wifi \
          && [ "$(nmcli radio wifi)" = "enabled" ]; then
        echo true
      else
        echo false
      fi
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

  # Bluetooth device menu (rofi) — the control-center tile opens this.
  # Known devices listed with connect state; picking one toggles the
  # connection. "Scan & pair" runs a timed scan then pairs+trusts+connects
  # the picked device. Works for audio/mice (JustWorks); PIN devices can
  # still be paired via blueman (entry at the bottom).
  xdg.configFile."swaync/bt-menu.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      bt=bluetoothctl

      power=$($bt show 2>/dev/null | awk '/Powered/{print $2; exit}')
      if [ "$power" != "yes" ]; then
          sel=$(printf ' Turn Bluetooth on\n' | rofi -dmenu -i -p "Bluetooth off")
          [ -n "$sel" ] && $bt power on >/dev/null 2>&1
          exit 0
      fi

      list() {
          $bt devices 2>/dev/null | while read -r _ mac name; do
              [ -z "$mac" ] && continue
              if $bt info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
                  st="●"; else st="○"; fi
              printf '%s %s\t%s\n' "$st" "$name" "$mac"
          done
      }

      sel=$({ list; printf '──────────────────\n  Scan & pair new…\n  Devices manager (blueman)\n  Turn Bluetooth off\n'; } \
              | rofi -dmenu -i -p "Bluetooth") || exit 0
      [ -n "$sel" ] || exit 0

      case "$sel" in
          *"Scan & pair"*)
              $bt scan on >/dev/null 2>&1 &
              scanpid=$!
              sleep 10
              $bt scan off >/dev/null 2>&1; kill $scanpid 2>/dev/null
              newdev=$( $bt devices 2>/dev/null \
                  | rofi -dmenu -i -p "Pair with" ) || exit 0
              [ -n "$newdev" ] || exit 0
              mac=$(printf '%s' "$newdev" | awk '{print $2}')
              [ -n "$mac" ] || exit 0
              $bt pair "$mac" >/dev/null 2>&1
              $bt trust "$mac" >/dev/null 2>&1
              $bt connect "$mac" >/dev/null 2>&1
              ;;
          *"blueman"*) blueman-manager >/dev/null 2>&1 & ;;
          *"Turn Bluetooth off"*) $bt power off >/dev/null 2>&1 ;;
          ─*)  exit 0 ;;
          *)   mac=''${sel##*$'\t'}
               [ -n "$mac" ] || exit 0
               if $bt info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
                   $bt disconnect "$mac" >/dev/null 2>&1
               else
                   $bt connect "$mac" >/dev/null 2>&1
               fi ;;
      esac
    '';
  };

}
