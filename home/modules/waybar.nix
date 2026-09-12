# Waybar — macOS-style top menu bar, full width, frosted glass.
{ config, pkgs, lib, ... }:
let
  theme = import ./theme.nix;
  nf = hex: builtins.fromJSON ''"\u${hex}"'';
  ic = {
    logo       = nf "f313";  # nf-linux-nixos
    # volume (Font Awesome — cleaner than MD variants)
    volLow     = nf "f026";  # nf-fa-volume_off
    volMid     = nf "f027";  # nf-fa-volume_low
    volHigh    = nf "f028";  # nf-fa-volume_high
    volMute    = nf "f00d";  # nf-fa-xmark
    # network
    wifi       = nf "f1eb";  # nf-fa-wifi
    ethernet   = nf "f1e6";  # nf-fa-plug (wired)
    wifiOff    = nf "f072";  # nf-fa-signal_off
    # bluetooth
    btOff      = nf "f293";  # nf-fa-bluetooth_b
    btOn       = nf "f294";  # nf-fa-bluetooth
    # battery
    bat        = [ (nf "f244") (nf "f243") (nf "f242") (nf "f241") (nf "f240") ];
    batCharge  = nf "f0e7";  # nf-fa-bolt
    batFull    = nf "f240";  # nf-fa-battery_full
    # system
    clock      = nf "f017";  # nf-fa-clock
    power      = nf "f011";  # nf-fa-power_off
    control    = nf "f013";  # nf-fa-gear
  };
in
{
  programs.waybar = {
    enable = true;

    settings = [{
      layer = "top";
      position = "top";
      height = 28;
      margin-top = 0;
      margin-left = 0;
      margin-right = 0;
      spacing = 0;

      modules-left = [ "custom/logo" "hyprland/workspaces" "custom/appname" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "bluetooth" "battery" "hyprland/language" "tray" "custom/control" "custom/power" ];

      "custom/logo" = {
        format = "${ic.logo}";
        on-click = "rofi -show drun";
        tooltip = false;
      };

      "custom/appname" = {
        format = "{}";
        exec = "$HOME/.config/waybar/appname.sh";
        interval = 1;
        tooltip = false;
      };

      "hyprland/workspaces" = {
        on-click = "activate";
        disable-scroll = true;
        all-outputs = false;
        show-special = false;
        persistent-only = true;
        sort-by = "number";
        format = "{name}";
        persistent-workspaces = {
          "*" = [ 1 2 3 4 5 ];
        };
      };

      "hyprland/language" = {
        format = " {} ";
        format-en = "EN";
        format-ru = "RU";
        min-length = 2;
        tooltip = false;
        on-click = "hyprctl switchxkblayout all next";
      };

      "pulseaudio" = {
        format = "{icon} {volume}%";
        format-muted = "${ic.volMute}";
        format-icons = {
          default = [ "${ic.volLow}" "${ic.volMid}" "${ic.volHigh}" ];
        };
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        scroll-step = 5;
        tooltip = false;
      };

      "network" = {
        format-wifi = "${ic.wifi}";
        format-ethernet = "${ic.ethernet}";
        format-disconnected = "${ic.wifiOff}";
        format-linked = "${ic.wifiOff}";
        tooltip-format = "{ipaddr}";
        on-click = "networkmanager_dmenu";
      };

      "bluetooth" = {
        format = "${ic.btOff}";
        format-connected = "${ic.btOn}";
        format-off = "${ic.btOff}";
        on-click = "rofi-bluetooth";
        tooltip = false;
      };

      "battery" = {
        format = "{icon} {capacity}%";
        format-charging = "${ic.batCharge} {capacity}%";
        format-full = "{icon} {capacity}%";
        format-icons = ic.bat;
        states = {
          warning = 30;
          critical = 15;
        };
        tooltip = false;
      };

      "tray" = {
        spacing = 8;
        icon-size = 16;
        show-passive-items = true;
      };

      "clock" = {
        format = "{:%a %d %b   %H:%M}";
        tooltip-format = "<tt>{calendar}</tt>";
        calendar = {
          mode = "month";
          mode-mon-col = 3;
          weeks-pos = "right";
          on-scroll = 1;
          format = {
            months = "";
            days = "<b>{}</b>";
            weeks = "<span color='${theme.subtext}'><b>W{}</b></span>";
            today = "<span color='${theme.purple}'><b><u>{}</u></b></span>";
          };
        };
        actions = {
          on-click-right = "mode";
          on-scroll-forward = "shift";
          on-scroll-backward = "shift";
        };
      };

      "custom/control" = {
        format = "${ic.control}";
        on-click = "swaync-client -t";
        tooltip = false;
      };

      "custom/power" = {
        format = "${ic.power}";
        on-click = "~/.config/rofi/powermenu.sh";
        tooltip = false;
      };
    }];

    style = ''
      * {
          font-family: "Inter", "JetBrainsMono Nerd Font Propo", "JetBrainsMono Nerd Font", "Noto Sans";
          font-size: 12px;
          border: none;
          border-radius: 0;
          min-height: 0;
      }

      window#waybar {
          background-color: rgba(20, 20, 27, 0.65);
          border-radius: 0;
      }

      window#waybar.hidden { opacity: 0.2; }

      #custom-logo, #custom-appname, #hyprland-workspaces, #hyprland-language,
      #pulseaudio, #network, #bluetooth, #battery, #tray, #clock,
      #custom-control, #custom-power {
          padding: 0 10px;
          margin: 0;
          background-color: transparent;
          color: ${theme.text};
          min-height: 28px;
      }

      #custom-logo, #pulseaudio, #network, #bluetooth, #battery,
      #custom-control, #custom-power, #hyprland-language {
          font-family: "JetBrainsMono Nerd Font Propo", "Inter", "Noto Sans";
      }

      #workspaces {
          padding: 0 4px;
      }

      #workspaces button {
          min-width: 22px;
          min-height: 22px;
          margin: 0 2px;
          padding: 0 6px;
          border-radius: 4px;
          color: ${theme.subtext};
          background-color: transparent;
          font-weight: 500;
      }

      #workspaces button:hover {
          background-color: ${theme.surface2};
          color: ${theme.text};
      }

      #workspaces button.active,
      #workspaces button.visible {
          background-color: ${theme.purple};
          color: ${theme.bg};
          font-weight: 600;
      }

      #workspaces button.urgent {
          background-color: ${theme.red};
          color: ${theme.bg};
      }

      #workspaces button.empty,
      #workspaces button.persistent {
          color: ${theme.subtext};
      }

      #language {
          color: ${theme.mauve};
          font-weight: 600;
          font-size: 11px;
          min-width: 22px;
      }

      #custom-logo {
          color: ${theme.purple};
          font-size: 16px;
          padding-left: 18px;
          padding-right: 6px;
      }

      #custom-appname {
          color: ${theme.text};
          font-weight: 500;
          padding-left: 0;
      }

      #clock {
          color: #ffffff;
          font-weight: 600;
          font-size: 13px;
      }

      #pulseaudio { color: ${theme.mauve}; }
      #network     { color: ${theme.blue}; }
      #bluetooth   { color: ${theme.blue}; }
      #battery     { color: ${theme.green}; }
      #battery.warning { color: ${theme.yellow}; }
      #battery.critical { color: ${theme.red}; }
      #battery.charging { color: ${theme.green}; }
      #custom-control { color: ${theme.subtext}; font-size: 13px; }
      #custom-power { color: ${theme.red}; font-size: 13px; }

      #tray { background-color: transparent; }

      #custom-power:hover {
          background-color: ${theme.red};
          color: ${theme.bg};
          border-radius: 4px;
      }

      #custom-logo:hover,
      #custom-appname:hover,
      #pulseaudio:hover,
      #network:hover,
      #bluetooth:hover,
      #battery:hover,
      #custom-control:hover,
      #tray:hover,
      #clock:hover,
      #hyprland-language:hover {
          background-color: ${theme.surface2};
          border-radius: 4px;
      }
    '';
  };

  # ─── Active application helper ─────────────────────────────────────
  xdg.configFile."waybar/appname.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      class=$(hyprctl -j activewindow 2>/dev/null \
        | ${pkgs.jq}/bin/jq -r '(.class // "") | ascii_downcase' 2>/dev/null)
      if [ -z "$class" ]; then
        echo "Desktop"
        exit 0
      fi
      case "$class" in
        firefox|firefox-esr|librewolf)   echo "Firefox" ;;
        *code*|code-oss|vscodium)        echo "Code" ;;
        telegram*|org.telegram.desktop)  echo "Telegram" ;;
        discord)                         echo "Discord" ;;
        dolphin|org.kde.dolphin)         echo "Files" ;;
        kitty|alacritty|foot|wezterm|gnome-terminal) echo "Terminal" ;;
        *)                               echo "''${class^}" ;;
      esac
    '';
  };
}
