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
    headphones = nf "f025";  # nf-fa-headphones
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
      height = 40;
      margin-top = 0;
      margin-left = 0;
      margin-right = 0;
      spacing = 0;

      # Two floating capsules: weather + workspaces left; lang, clock,
      # volume, tray, battery, control-center icon right. Nothing else.
      modules-left = [ "custom/weather" "hyprland/workspaces" ];
      modules-right = [ "hyprland/language" "custom/clock" "custom/volume" "tray" "battery" "custom/cc" ];

      "custom/weather" = {
        exec = "~/.config/hypr/scripts/weather.sh";
        "return-type" = "json";
        interval = 1800;
        max-length = 30;
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

      "custom/clock" = {
        exec = "~/.config/hypr/scripts/clock.sh";
        "return-type" = "json";
        interval = 5;
        on-click = "${pkgs.gsimplecal}/bin/gsimplecal";
        tooltip = true;
      };

      # Volume with headphone detection: speaker glyph normally,
      # headphones when the default sink is a wired jack port or a
      # bluetooth device; BT battery shows in the tooltip.
      "custom/volume" = {
        exec = "~/.config/waybar/volume.sh";
        "return-type" = "json";
        interval = 2;
        on-click = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        on-scroll-up = "${pkgs.wireplumber}/bin/wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+";
        on-scroll-down = "${pkgs.wireplumber}/bin/wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%-";
        tooltip = true;
      };

      "tray" = {
        spacing = 8;
        icon-size = 16;
        show-passive-items = true;
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

      # NixOS glyph — the single accent of the right capsule.
      # Opens the control center.
      "custom/cc" = {
        format = "${ic.logo}";
        on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client -t";
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

      /* Fully transparent strip — the capsules are the only visible
         elements; shadow and blur belong to them, not the bar. */
      window#waybar {
          background-color: transparent;
      }

      window#waybar.hidden { opacity: 0.2; }

      .modules-left, .modules-right {
          background-color: alpha(@bg, 0.55);
          border: 1px solid alpha(@purple, 0.18);
          border-radius: 999px;
          padding: 0 14px;
          margin-top: 6px;
          margin-bottom: 4px;
      }
      .modules-left  { margin-left: 12px; }
      .modules-right { margin-right: 12px; }

      /* All module text is subtext — the capsule stays quiet; purple is
         reserved for things that carry information. */
      #custom-weather, #workspaces, #language, #custom-clock, #custom-volume,
      #tray, #battery, #custom-cc {
          padding: 0 6px;
          background-color: transparent;
          color: @subtext;
          min-height: 30px;
      }

      #custom-weather { padding-right: 8px; }

      #workspaces button {
          min-width: 20px;
          min-height: 20px;
          margin: 5px 2px;
          padding: 0;
          border-radius: 999px;
          color: @subtext;
          background-color: transparent;
          font-weight: 600;
      }

      #workspaces button:hover {
          background-color: alpha(@purple, 0.3);
          color: @text;
      }

      #workspaces button.active,
      #workspaces button.visible {
          background-color: @purple;
          color: @bg;
      }

      #workspaces button.urgent {
          background-color: @red;
          color: @bg;
      }

      #language {
          font-weight: 600;
          font-size: 11px;
          min-width: 22px;
      }

      #custom-clock {
          color: @text;
          font-weight: 600;
          font-size: 13px;
      }

      #custom-volume.headphones { color: @mauve; }
      #custom-volume.muted      { color: @muted; }

      #battery.warning  { color: @yellow; }
      #battery.critical { color: @red; }
      #battery.charging { color: @green; }

      #custom-cc {
          color: @purple;
          font-size: 15px;
          padding: 0 2px 0 6px;
      }

      #tray { background-color: transparent; }

      #custom-weather:hover, #custom-clock:hover, #custom-volume:hover,
      #battery:hover, #custom-cc:hover, #tray:hover,
      #language:hover {
          background-color: alpha(@surface2, 0.7);
          border-radius: 999px;
      }
    '';
  };

  # ─── Volume module helper ──────────────────────────────────────────
  # Emits JSON for custom/volume: speaker glyph by level, headphones
  # glyph for a wired-jack port or any bluetooth sink, mute x-mark,
  # BT headset battery in the tooltip via upower.
  xdg.configFile."waybar/volume.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      pactl=${pkgs.pulseaudio}/bin/pactl
      wpctl=${pkgs.wireplumber}/bin/wpctl
      upower=${pkgs.upower}/bin/upower

      sink=$($pactl get-default-sink 2>/dev/null)
      info=$($wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
      pct=$(printf '%s' "$info" | awk '{printf "%d", $2*100}')
      [ -z "$pct" ] && pct=0

      icon=""   # nf-fa-volume_high
      class=""
      if printf '%s' "$info" | grep -q MUTED; then
          icon=""   # nf-fa-xmark
          class="muted"
      else
          # wired jack -> active port says headphones; BT -> bluez_* sink
          port=$($pactl list sinks 2>/dev/null \
              | awk -v s="$sink" '
                  $0 ~ "Name: "s {f=1; next}
                  f && /^[[:space:]]*Name: / {f=0}
                  f && /Active Port:/ {print $3; exit}')
          hp=
          case "$port" in *headphone*|*Headphone*) hp=1 ;; esac
          case "$sink" in bluez*) hp=1 ;; esac
          if [ -n "$hp" ]; then
              icon=""   # nf-fa-headphones
              class="headphones"
          else
              [ "$pct" -lt 34 ] && icon=""   # volume_off
              [ "$pct" -lt 67 ] && icon=""   # volume_low
          fi
      fi

      tip="volume"
      if [ "$class" = "headphones" ]; then
          dev=$($upower -e 2>/dev/null \
              | grep -iE 'headset|headphone|bluez' | head -1)
          [ -n "$dev" ] && \
              bat=$($upower -i "$dev" 2>/dev/null \
                  | awk '/percentage/{print $2; exit}')
          [ -n "$bat" ] && tip="headphones: $bat"
      fi

      printf '{"text":"%s %s%%","tooltip":"%s","class":"%s"}\n' \
          "$icon" "$pct" "$tip" "$class"
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

      # defaults mirror style.css (30px modules inside the capsules)
      ICON_PAD=0; WS_MARGIN=5; WS_WIDTH=20; WS_HP=0; WEATHER_LEFT=6; CC_RIGHT=2; MOD_PAD=6
      [ -f "$ENV" ] && . "$ENV" || true

      render() {
          # GTK adds padding on top of min-height, so we shrink min-height
          # to keep every module exactly 30px while nudging its content.
          local mh=$(( 30 - ICON_PAD )); [ "$mh" -lt 0 ] && mh=0
          local wmh=$(( 30 - 2 * WS_MARGIN )); [ "$wmh" -lt 0 ] && wmh=0
          cat > "$FILE" <<CSS
      /* waybar-tune overrides — regenerated, do not edit by hand. */
      window#waybar #custom-weather, window#waybar #hyprland-workspaces,
      window#waybar #hyprland-language, window#waybar #custom-clock,
      window#waybar #custom-volume, window#waybar #tray,
      window#waybar #battery, window#waybar #custom-cc {
          padding-left: ''${MOD_PAD}px;
          padding-right: ''${MOD_PAD}px;
      }
      window#waybar #custom-weather { padding-left: ''${WEATHER_LEFT}px; }
      window#waybar #custom-cc      { padding-right: ''${CC_RIGHT}px; }

      window#waybar #custom-weather, window#waybar #hyprland-language,
      window#waybar #custom-clock, window#waybar #custom-volume,
      window#waybar #tray, window#waybar #battery, window#waybar #custom-cc {
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
          printf 'ICON_PAD=%s\nWS_MARGIN=%s\nWS_WIDTH=%s\nWS_HP=%s\nWEATHER_LEFT=%s\nCC_RIGHT=%s\nMOD_PAD=%s\n' \
              "$ICON_PAD" "$WS_MARGIN" "$WS_WIDTH" "$WS_HP" "$WEATHER_LEFT" "$CC_RIGHT" "$MOD_PAD" > "$ENV"
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
                  "ICON_PAD     icons/text up-down  = $ICON_PAD" \
                  "WS_MARGIN    ws buttons up-down = $WS_MARGIN" \
                  "WS_WIDTH     ws button width    = $WS_WIDTH" \
                  "WS_HP        ws button horiz    = $WS_HP" \
                  "WEATHER_LEFT weather left pad   = $WEATHER_LEFT" \
                  "CC_RIGHT     cc icon right pad  = $CC_RIGHT" \
                  "MOD_PAD      module horiz pad   = $MOD_PAD" \
                  "reset" \
                  "quit" \
                  | rofi -dmenu -i -p "waybar-tune") || break
              [ -z "$sel" ] && break
              key=''${sel%% *}
              case "$key" in
                  reset) reset_all ;;
                  quit)  break ;;
                  ICON_PAD|WS_MARGIN|WS_WIDTH|WS_HP|WEATHER_LEFT|CC_RIGHT|MOD_PAD) step "$key" ;;
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
                     ICON_PAD|WS_MARGIN|WS_WIDTH|WS_HP|WEATHER_LEFT|CC_RIGHT|MOD_PAD)
                         [[ "$val" =~ ^-?[0-9]+$ ]] || { echo "waybar-tune: value must be an integer" >&2; exit 1; }
                         printf -v "$key" '%s' "$val"; render ;;
                     *) echo "waybar-tune: unknown key '$key'" >&2; exit 1 ;;
                 esac ;;
          bump)  key=''${2:?usage: waybar-tune bump KEY N}
                 d=''${3:?usage: waybar-tune bump KEY N}
                 case "$key" in
                     ICON_PAD|WS_MARGIN|WS_WIDTH|WS_HP|WEATHER_LEFT|CC_RIGHT|MOD_PAD)
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
