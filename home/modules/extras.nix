# Extra convenience features: keybind cheatsheet, night light, screen
# recording, caffeine (idle inhibit), weather — scripts + packages.
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    hyprsunset     # night light daemon
    wf-recorder    # screen recording
    pwvucontrol    # per-app volume mixer
    playerctl      # mpris control for waybar clicks
    btop           # task manager (opened from waybar sys modules)
  ];

  # ─── Keybind cheatsheet (SUPER+/) ───────────────────────────────────
  # Parses hyprland.lua on the fly so the list always matches the live
  # config, then shows it in rofi.
  xdg.configFile."hypr/scripts/cheatsheet.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      LUA="$HOME/.config/hypr/hyprland.lua"

      {
      grep 'hl\.bind(' "$LUA" | while IFS= read -r line; do
          key=$(printf '%s' "$line" | sed -E 's/.*hl\.bind\(([^,]+),.*/\1/')
          case "$key" in *key*) continue ;; esac   # loop-generated ws binds, covered below
          key=$(printf '%s' "$key" | sed -E 's/mainMod *\.\. */SUPER /g; s/"//g' | tr -s ' ')
          dsp=$(printf '%s' "$line" | sed -nE 's/.*hl\.dsp\.([a-zA-Z_.]+)\(([^)]*)\).*/\1|\2/p')
          [ -z "$dsp" ] && continue
          name="''${dsp%%|*}"; arg="''${dsp#*|}"; arg="''${arg//\"/}"
          case "$name" in
              exec_cmd)
                  a=$(printf '%s' "$arg" | sed -E 's|/nix/store/[^/]+/bin/||g; s|[^ ]*/scripts/||g')
                  act="run: $a" ;;
              window.close)             act="close window" ;;
              window.float)             act="toggle floating" ;;
              window.fullscreen)        act="toggle fullscreen" ;;
              window.pseudo)            act="pseudo tile" ;;
              window.pin)               act="pin window on top" ;;
              window.drag)              act="mouse: drag window" ;;
              window.resize)            act="mouse: resize window" ;;
              window.move)              act="move window -> $arg" ;;
              focus)                    act="focus -> $arg" ;;
              layout)                   act="layout: $arg" ;;
              workspace.toggle_special) act="scratchpad $arg" ;;
              exit)                     act="exit Hyprland" ;;
              *)                        act="$name $arg" ;;
          esac
          printf '%-26s %s\n' "$key" "$act"
      done
      printf '%-26s %s\n' "SUPER + 1..9"         "focus workspace N"
      printf '%-26s %s\n' "SUPER + SHIFT + 1..9" "move window to ws N"
      } | rofi -dmenu -i -p "keybinds" -theme-str 'window {width: 860px;}'
    '';
  };

  # ─── Night light toggle (SUPER+SHIFT+N) ─────────────────────────────
  # `auto` mode is called from autostart: enables itself in the evening.
  xdg.configFile."hypr/scripts/nightlight.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      TEMP=4000
      case "''${1:-toggle}" in
          auto)
              h=$(date +%H); [ "$h" -ge 20 ] || [ "$h" -lt 7 ] || exit 0
              pgrep -x hyprsunset >/dev/null || ${pkgs.hyprsunset}/bin/hyprsunset -t "$TEMP" >/dev/null 2>&1 & ;;
          on)
              pgrep -x hyprsunset >/dev/null || ${pkgs.hyprsunset}/bin/hyprsunset -t "$TEMP" >/dev/null 2>&1 & ;;
          off)
              pkill -x hyprsunset 2>/dev/null || true ;;
          *)
              if pgrep -x hyprsunset >/dev/null; then
                  pkill -x hyprsunset
                  notify-send "Night light" "off" 2>/dev/null || true
              else
                  ${pkgs.hyprsunset}/bin/hyprsunset -t "$TEMP" >/dev/null 2>&1 &
                  notify-send "Night light" "on (''${TEMP}K)" 2>/dev/null || true
              fi ;;
      esac
    '';
  };

  # ─── Screen recording (SUPER+SHIFT+Print) ───────────────────────────
  # Press once: select an area, recording starts. Press again: stops and
  # saves to ~/Videos/rec-<timestamp>.mp4.
  xdg.configFile."hypr/scripts/record.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      DIR="$HOME/Videos"
      if pgrep -x wf-recorder >/dev/null; then
          pkill -INT -x wf-recorder
          notify-send "Screen record" "saved to $DIR" 2>/dev/null || true
      else
          mkdir -p "$DIR"
          f="$DIR/rec-$(date +%F_%H-%M-%S).mp4"
          notify-send "Screen record" "select an area…" 2>/dev/null || true
          ${pkgs.wf-recorder}/bin/wf-recorder -g "$(${pkgs.slurp}/bin/slurp)" -f "$f" >/dev/null 2>&1 &
      fi
    '';
  };

  # ─── Caffeine / idle inhibit (waybar toggle) ────────────────────────
  # `status` prints JSON for the waybar module; `toggle` flips a
  # systemd-inhibit idle lock that hypridle respects.
  xdg.configFile."hypr/scripts/caffeine.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      case "''${1:-status}" in
          toggle)
              if pgrep -f 'why=caffeine' >/dev/null; then
                  pkill -f 'why=caffeine'
                  notify-send "Caffeine" "idle lock enabled" 2>/dev/null || true
              else
                  ${pkgs.systemd}/bin/systemd-inhibit --what=idle:shutdown:sleep \
                      --why=caffeine --who=caffeine --mode=block \
                      sleep infinity >/dev/null 2>&1 &
                  disown
                  notify-send "Caffeine" "screen stays on" 2>/dev/null || true
              fi ;;
          *)
              g=$(printf '')
              if pgrep -f 'why=caffeine' >/dev/null; then
                  printf '{"text":"%s","tooltip":"caffeine on — idle lock inhibited","class":"on"}\n' "$g"
              else
                  printf '{"text":"%s","tooltip":"caffeine off","class":"off"}\n' "$g"
              fi ;;
      esac
    '';
  };

  # ─── Player control buttons (waybar mpris drawer) ───────────────────
  # Prints the glyph for each button; "play" reflects playerctl status.
  xdg.configFile."hypr/scripts/player-buttons.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      s=$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null)
      [ -z "$s" ] && exit 0   # no player -> empty module
      case "$1" in
          play) [ "$s" = "Playing" ] && printf '⏸' || printf '▶' ;;
          prev) printf '⏮' ;;
          next) printf '⏭' ;;
          stop) printf '⏹' ;;
      esac
    '';
  };

  # ─── Weather (waybar module, wttr.in) ───────────────────────────────
  xdg.configFile."hypr/scripts/weather.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # %t = "+14°C", %c = weather emoji, %C = text condition (tooltip).
      out=$(curl -s --max-time 5 'wttr.in/?format=%t+%c|%C&lang=ru' 2>/dev/null)
      if [ -n "$out" ]; then
          printf '{"text":"%s","tooltip":"%s"}\n' "''${out%%|*}" "''${out##*|}"
      else
          echo '{"text":""}'
      fi
    '';
  };
}
