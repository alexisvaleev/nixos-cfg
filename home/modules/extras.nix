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
    gsimplecal     # month calendar popup (waybar clock click)
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

  # ─── Night light toggle (SUPER+SHIFT+N or the waybar button) ────────
  # Purely manual — no schedule. `status` prints the waybar JSON state.
  xdg.configFile."hypr/scripts/nightlight.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      TEMP=4000
      start() { pgrep -x hyprsunset >/dev/null || ${pkgs.hyprsunset}/bin/hyprsunset -t "$TEMP" >/dev/null 2>&1 & }
      stop()  { pkill -x hyprsunset 2>/dev/null || true; }
      case "''${1:-toggle}" in
          status)
              if pgrep -x hyprsunset >/dev/null; then
                  printf '{"text": "\\uf186", "class": "on", "tooltip": "night light on (%sK) — click to turn off"}\n' "$TEMP"
              else
                  printf '{"text": "\\uf185", "class": "off", "tooltip": "night light off — click to turn on"}\n'
              fi ;;
          on)  start ;;
          off) stop ;;
          *)
              if pgrep -x hyprsunset >/dev/null; then
                  stop
                  notify-send "Night light" "off" 2>/dev/null || true
              else
                  start
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

  # ─── Caffeine / idle inhibit (control center toggle) ────────────────
  # `on`/`off` set a systemd-inhibit idle lock that hypridle respects;
  # `toggle` flips it. `status` prints waybar-style JSON (debug).
  xdg.configFile."hypr/scripts/caffeine.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      on()  { pgrep -f 'why=caffeine' >/dev/null || \
              ${pkgs.systemd}/bin/systemd-inhibit --what=idle:shutdown:sleep \
                  --why=caffeine --who=caffeine --mode=block \
                  sleep infinity >/dev/null 2>&1 & disown; }
      off() { pkill -f 'why=caffeine' 2>/dev/null || true; }
      case "''${1:-status}" in
          on)  on ;;
          off) off ;;
          toggle)
              if pgrep -f 'why=caffeine' >/dev/null; then
                  off
                  notify-send "Caffeine" "idle lock enabled" 2>/dev/null || true
              else
                  on
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

  # ─── Raise the window the track is playing from ─────────────────────
  # Maps the mpris player name ("firefox.instance_1_x" -> "firefox") to a
  # Hyprland client class and focuses that window.
  xdg.configFile."hypr/scripts/player-raise.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      p=$(${pkgs.playerctl}/bin/playerctl -l 2>/dev/null | head -1)
      [ -z "$p" ] && exit 0
      base=$(printf '%s' "$p" | cut -d. -f1)
      addr=$(hyprctl clients -j | ${pkgs.jq}/bin/jq -r --arg p "$base" \
          '.[] | select(.class | ascii_downcase | contains($p | ascii_downcase)) | .address' \
          | head -1)
      [ -n "$addr" ] && [ "$addr" != "null" ] && \
          hyprctl dispatch focuswindow "address:$addr"
    '';
  };

  # ─── Combined system stats (one waybar cell) ────────────────────────
  # " cpu%  mem%  temp°" — cpu delta is stored between polls in /tmp.
  xdg.configFile."hypr/scripts/sysstats.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      f=/tmp/sysstat-cpu
      read -r _ u n s i iw io st _ < /proc/stat
      t=$((u+n+s+i+iw+io+st)); idl=$((i+iw))
      cpu=0
      if [ -f "$f" ]; then
          read -r pt pidl < "$f"
          dt=$((t-pt)); di=$((idl-pidl))
          [ "$dt" -gt 0 ] && cpu=$(( (dt-di)*100/dt ))
      fi
      echo "$t $idl" > "$f"

      mem=$(awk '/MemTotal/{T=$2} /MemAvailable/{A=$2} END{printf "%d",(T-A)*100/T}' /proc/meminfo)

      tmax=0
      for z in /sys/class/thermal/thermal_zone*/temp; do
          v=$(cat "$z" 2>/dev/null) || continue
          [ "$v" -gt "$tmax" ] && tmax=$v
      done
      temp=$((tmax/1000))

      printf '%s %s%%  %s %s%%  %s %s°\n' \
          $'\uf2db' "$cpu" $'\U000f035b' "$mem" $'\uf2c9' "$temp"
    '';
  };

  # ─── Clock with Russian day/month names ─────────────────────────────
  # The system only ships en_US locale, so the built-in clock can only
  # print English names — hardcode Russian ones instead:
  # "10:15   18 сентября, четверг".
  xdg.configFile."hypr/scripts/clock.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      case "$(date +%-m)" in
          1) m=января;; 2) m=февраля;; 3) m=марта;; 4) m=апреля;; 5) m=мая;; 6) m=июня;;
          7) m=июля;; 8) m=августа;; 9) m=сентября;; 10) m=октября;; 11) m=ноября;; 12) m=декабря;;
      esac
      case "$(date +%u)" in
          1) w=понедельник;; 2) w=вторник;; 3) w=среда;; 4) w=четверг;; 5) w=пятница;; 6) w=суббота;; 7) w=воскресенье;;
      esac
      printf '{"text":"%s   %s %s, %s","tooltip":"%s"}\n' \
          "$(date +%H:%M)" "$(date +%-d)" "$m" "$w" "$(date '+%d.%m.%Y, неделя %V')"
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
