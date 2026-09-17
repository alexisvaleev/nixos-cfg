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
    # extras
    music      = nf "f001";  # nf-fa-music
    cpu        = nf "f2db";  # nf-fa-microchip
    mem        = nf "f538";  # nf-fa-memory
    temp       = nf "f2c9";  # nf-fa-thermometer_half
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
      modules-right = [ "custom/weather" "group/player" "cpu" "memory" "temperature" "pulseaudio" "network" "bluetooth" "battery" "hyprland/language" "custom/caffeine" "tray" "custom/control" "custom/power" ];

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
        sort-by = "number";
        format = "{id}";
        tooltip-format = "{name}";
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

      # Player group: track title is always visible; hovering slides out
      # ⏮ ⏯ ⏹ ⏭ controls. Scrolling the title seeks ±10s like a slider.
      "group/player" = {
        orientation = "inherit";
        drawer = {
          "transition-duration" = 300;
          "children-class" = "player-controls";
          "transition-left-to-right" = false;
          "click-to-reveal" = false;
        };
        modules = [ "mpris" "custom/player-prev" "custom/player-play" "custom/player-stop" "custom/player-next" ];
      };

      "mpris" = {
        format = "${ic.music} {artist} - {title}";
        format-paused = "${ic.music} {artist} - {title}";
        max-length = 35;
        on-click = "${pkgs.playerctl}/bin/playerctl play-pause";
        on-click-middle = "${pkgs.playerctl}/bin/playerctl stop";
        on-scroll-up = "${pkgs.playerctl}/bin/playerctl position 10+";
        on-scroll-down = "${pkgs.playerctl}/bin/playerctl position 10-";
        tooltip-format = "{player}: {position} / {length}";
      };

      "custom/player-prev" = {
        exec = "~/.config/hypr/scripts/player-buttons.sh prev";
        interval = 1;
        on-click = "${pkgs.playerctl}/bin/playerctl previous";
        tooltip = false;
      };
      "custom/player-play" = {
        exec = "~/.config/hypr/scripts/player-buttons.sh play";
        interval = 1;
        on-click = "${pkgs.playerctl}/bin/playerctl play-pause";
        tooltip = false;
      };
      "custom/player-stop" = {
        exec = "~/.config/hypr/scripts/player-buttons.sh stop";
        interval = 1;
        on-click = "${pkgs.playerctl}/bin/playerctl stop";
        tooltip = false;
      };
      "custom/player-next" = {
        exec = "~/.config/hypr/scripts/player-buttons.sh next";
        interval = 1;
        on-click = "${pkgs.playerctl}/bin/playerctl next";
        tooltip = false;
      };

      "cpu" = {
        format = "${ic.cpu} {usage}%";
        on-click = "kitty --class btop-float -e ${pkgs.btop}/bin/btop";
        tooltip = false;
      };

      "memory" = {
        format = "${ic.mem} {percentage}%";
        on-click = "kitty --class btop-float -e ${pkgs.btop}/bin/btop";
        tooltip = false;
      };

      "temperature" = {
        format = "${ic.temp} {temperatureC}°";
        on-click = "kitty --class btop-float -e ${pkgs.btop}/bin/btop";
        tooltip = false;
      };

      "custom/weather" = {
        exec = "~/.config/hypr/scripts/weather.sh";
        "return-type" = "json";
        interval = 1800;
        max-length = 30;
      };

      "custom/caffeine" = {
        exec = "~/.config/hypr/scripts/caffeine.sh";
        "return-type" = "json";
        interval = 5;
        on-click = "~/.config/hypr/scripts/caffeine.sh toggle";
        tooltip = true;
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
      @import "/home/blessed/.config/theme/colors.css";
      @import "/home/blessed/.config/waybar/adjust.css";

      * {
          font-family: "Inter", "Iosevka Nerd Font Propo", "JetBrainsMono Nerd Font", "Noto Sans";
          font-size: 12px;
          border: none;
          border-radius: 0;
          min-height: 0;
      }

      window#waybar {
          background-color: alpha(@bg, 0.65);
          border-radius: 0;
      }

      window#waybar.hidden { opacity: 0.2; }

      #custom-logo, #custom-appname, #hyprland-workspaces, #hyprland-language,
      #pulseaudio, #network, #bluetooth, #battery, #tray, #clock,
      #custom-control, #custom-power,
      #mpris, #cpu, #memory, #temperature, #custom-weather, #custom-caffeine {
          padding: 0 10px;
          margin: 0;
          background-color: transparent;
          color: @text;
          min-height: 28px;
      }

      #custom-logo, #pulseaudio, #network, #bluetooth, #battery,
      #custom-control, #custom-power, #hyprland-language,
      #mpris, #cpu, #memory, #temperature, #custom-weather, #custom-caffeine {
          font-family: "Iosevka Nerd Font Propo", "JetBrainsMono Nerd Font", "Inter", "Noto Sans";
      }

      #workspaces {
          padding: 0 4px;
      }

      #workspaces button {
          min-width: 22px;
          min-height: 22px;
          margin: 3px 2px;
          padding: 0;
          border-radius: 4px;
          color: @subtext;
          background-color: transparent;
          font-weight: 500;
      }

      #workspaces button:hover {
          background-color: @surface2;
          color: @text;
      }

      #workspaces button.active,
      #workspaces button.visible {
          background-color: @purple;
          color: @bg;
          font-weight: 600;
      }

      #workspaces button.urgent {
          background-color: @red;
          color: @bg;
      }

      #workspaces button.empty,
      #workspaces button.persistent {
          color: @subtext;
      }

      #language {
          color: @mauve;
          font-weight: 600;
          font-size: 11px;
          min-width: 22px;
      }

      #custom-logo {
          color: @purple;
          font-size: 16px;
          padding-left: 18px;
          padding-right: 6px;
      }

      #custom-appname {
          color: @text;
          font-weight: 500;
          padding-left: 0;
      }

      #clock {
          color: #ffffff;
          font-weight: 600;
          font-size: 13px;
      }

      #pulseaudio { color: @mauve; }
      #network     { color: @blue; }
      #bluetooth   { color: @blue; }
      #battery     { color: @green; }
      #mpris        { color: @purple; }
      #cpu          { color: @blue; }
      #memory       { color: @mauve; }
      #temperature  { color: @yellow; }
      #custom-weather   { color: @blue; }
      #custom-caffeine  { color: @subtext; }
      #custom-caffeine.on { color: @green; }

      /* Player drawer buttons — compact, purple accent. */
      #custom-player-prev, #custom-player-play,
      #custom-player-stop, #custom-player-next {
          padding: 0 5px;
          min-height: 28px;
          color: @purple;
          font-size: 13px;
      }
      .player-controls {
          background-color: alpha(@surface2, 0.5);
          border-radius: 6px;
      }
      #battery.warning { color: @yellow; }
      #battery.critical { color: @red; }
      #battery.charging { color: @green; }
      #custom-control { color: @subtext; font-size: 13px; }
      #custom-power { color: @red; font-size: 13px; }

      #tray { background-color: transparent; }

      #custom-power:hover {
          background-color: @red;
          color: @bg;
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
      #hyprland-language:hover,
      #mpris:hover,
      #cpu:hover,
      #memory:hover,
      #temperature:hover,
      #custom-weather:hover,
      #custom-caffeine:hover {
          background-color: @surface2;
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

  # ─── Live spacing tuner ─────────────────────────────────────────────
  # Writes ~/.config/waybar/adjust.css (imported by style.css above; its
  # window#waybar-prefixed selectors are more specific and therefore win)
  # then reloads waybar's CSS via SIGUSR2 so every tweak is seen instantly.
  xdg.configFile."hypr/scripts/waybar-tune" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      DIR="$HOME/.config/waybar"
      FILE="$DIR/adjust.css"
      ENV="$DIR/tune.env"

      # defaults mirror style.css
      ICON_PAD=0; WS_MARGIN=3; WS_WIDTH=22; WS_HP=0; LOGO_LEFT=18; APP_LEFT=0; MOD_PAD=10
      [ -f "$ENV" ] && . "$ENV" || true

      render() {
          # GTK adds padding on top of min-height, so we shrink min-height
          # to keep every module exactly 28px while nudging its content.
          local mh=$(( 28 - ICON_PAD )); [ "$mh" -lt 0 ] && mh=0
          local wmh=$(( 28 - 2 * WS_MARGIN )); [ "$wmh" -lt 0 ] && wmh=0
          cat > "$FILE" <<CSS
      /* waybar-tune overrides — regenerated, do not edit by hand. */
      window#waybar #custom-logo, window#waybar #custom-appname,
      window#waybar #hyprland-workspaces, window#waybar #hyprland-language,
      window#waybar #pulseaudio, window#waybar #network, window#waybar #bluetooth,
      window#waybar #battery, window#waybar #tray, window#waybar #clock,
      window#waybar #custom-control, window#waybar #custom-power,
      window#waybar #mpris, window#waybar #cpu, window#waybar #memory,
      window#waybar #temperature, window#waybar #custom-weather,
      window#waybar #custom-caffeine {
          padding-left: ''${MOD_PAD}px;
          padding-right: ''${MOD_PAD}px;
      }
      window#waybar #custom-logo    { padding-left: ''${LOGO_LEFT}px; }
      window#waybar #custom-appname { padding-left: ''${APP_LEFT}px; }

      window#waybar #custom-logo, window#waybar #network, window#waybar #bluetooth,
      window#waybar #custom-control, window#waybar #custom-power,
      window#waybar #custom-appname, window#waybar #pulseaudio,
      window#waybar #battery, window#waybar #hyprland-language, window#waybar #clock,
      window#waybar #mpris, window#waybar #cpu, window#waybar #memory,
      window#waybar #temperature, window#waybar #custom-weather,
      window#waybar #custom-caffeine {
          min-height: ''${mh}px;
          padding-top: ''${ICON_PAD}px;
      }
      window#waybar #workspaces button {
          min-height: ''${wmh}px;
          margin: ''${WS_MARGIN}px 2px;
          min-width: ''${WS_WIDTH}px;
          padding: 0 ''${WS_HP}px;
      }
      CSS
          printf 'ICON_PAD=%s\nWS_MARGIN=%s\nWS_WIDTH=%s\nWS_HP=%s\nLOGO_LEFT=%s\nAPP_LEFT=%s\nMOD_PAD=%s\n' \
              "$ICON_PAD" "$WS_MARGIN" "$WS_WIDTH" "$WS_HP" "$LOGO_LEFT" "$APP_LEFT" "$MOD_PAD" > "$ENV"
          pkill -SIGUSR2 -x waybar 2>/dev/null || true
      }

      reset_all() {
          : > "$FILE"
          rm -f "$ENV"
          pkill -SIGUSR2 -x waybar 2>/dev/null || true
      }

      step() {
          local key=$1 d n
          while true; do
              d=$(printf '%s\n' "-4" "-2" "-1" "+1" "+2" "+4" "set…" "done" \
                  | rofi -dmenu -i -p "$key = ''${!key}") || break
              [ -z "$d" ] && break
              case "$d" in
                  done) break ;;
                  set…) n=$(echo | rofi -dmenu -p "value for $key" || true)
                        [[ "''${n:-}" =~ ^-?[0-9]+$ ]] && printf -v "$key" '%s' "$n" ;;
                  *)    [[ "$d" =~ ^[+-]?[0-9]+$ ]] \
                          && printf -v "$key" '%d' "$(( ''${!key} + d ))" ;;
              esac
              render
          done
      }

      menu() {
          local sel key
          while true; do
              sel=$(printf '%s\n' \
                  "ICON_PAD   icons/text up-down  = $ICON_PAD" \
                  "WS_MARGIN  ws buttons up-down = $WS_MARGIN" \
                  "WS_WIDTH   ws button width    = $WS_WIDTH" \
                  "WS_HP      ws button horiz    = $WS_HP" \
                  "LOGO_LEFT  logo left pad      = $LOGO_LEFT" \
                  "APP_LEFT   appname left pad   = $APP_LEFT" \
                  "MOD_PAD    module horiz pad   = $MOD_PAD" \
                  "reset" \
                  "quit" \
                  | rofi -dmenu -i -p "waybar-tune") || break
              [ -z "$sel" ] && break
              key=''${sel%% *}
              case "$key" in
                  reset) reset_all ;;
                  quit)  break ;;
                  ICON_PAD|WS_MARGIN|WS_WIDTH|WS_HP|LOGO_LEFT|APP_LEFT|MOD_PAD) step "$key" ;;
                  *) break ;;
              esac
          done
      }

      case "''${1:-menu}" in
          menu)  menu ;;
          show)  cat "$FILE" 2>/dev/null || true ;;
          reset) reset_all ;;
          set)   key=''${2:?usage: waybar-tune set KEY VALUE}
                 val=''${3:?usage: waybar-tune set KEY VALUE}
                 case "$key" in
                     ICON_PAD|WS_MARGIN|WS_WIDTH|WS_HP|LOGO_LEFT|APP_LEFT|MOD_PAD)
                         [[ "$val" =~ ^-?[0-9]+$ ]] || { echo "waybar-tune: value must be an integer" >&2; exit 1; }
                         printf -v "$key" '%s' "$val"; render ;;
                     *) echo "waybar-tune: unknown key '$key'" >&2; exit 1 ;;
                 esac ;;
          bump)  key=''${2:?usage: waybar-tune bump KEY N}
                 d=''${3:?usage: waybar-tune bump KEY N}
                 case "$key" in
                     ICON_PAD|WS_MARGIN|WS_WIDTH|WS_HP|LOGO_LEFT|APP_LEFT|MOD_PAD)
                         printf -v "$key" '%d' "$(( ''${!key} + d ))"; render ;;
                     *) echo "waybar-tune: unknown key '$key'" >&2; exit 1 ;;
                 esac ;;
          *)     echo "usage: waybar-tune [menu|show|reset|set KEY VAL|bump KEY ±N]" >&2; exit 1 ;;
      esac
    '';
  };

  # adjust.css must exist so the @import above never fails; it is a real
  # writable file (not a store symlink) so waybar-tune can rewrite it.
  home.activation.waybarAdjustCss = lib.hm.dag.entryAfter ["linkGeneration"] ''
    if [ ! -f "$HOME/.config/waybar/adjust.css" ]; then
      run printf '/* waybar-tune overrides — managed by ~/.config/hypr/scripts/waybar-tune */\n' \
        > "$HOME/.config/waybar/adjust.css" || true
    fi
  '';
}
