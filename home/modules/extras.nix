# Extra convenience features: keybind cheatsheet, night light, screen
# recording, caffeine (idle inhibit), weather — scripts + packages.
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    # (no hyprsunset — night light is a Hyprland screen_shader; the
    # KMS-CTM path hyprsunset needs is unavailable on legacy-iface DRM)
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

  # ─── Night light toggle (SUPER+SHIFT+N or the swaync button) ────────
  # Implemented as a Hyprland screen_shader — a pure render-side effect
  # that works on any DRM backend. hyprsunset is NOT used: it needs an
  # atomic KMS CTM, and aquamarine falls back to the legacy iface on
  # nouveau+GSP ("No support for gamma on the legacy iface").
  xdg.configFile."hypr/shaders/nightlight.glsl" = {
    text = ''
      #version 300 es
      precision highp float;
      in vec2 v_texcoord;
      uniform sampler2D tex;
      layout(location = 0) out vec4 fragColor;

      // Warm tint, roughly ~4000K.
      void main() {
          vec4 c = texture(tex, v_texcoord);
          c.g *= 0.75;
          c.b *= 0.45;
          fragColor = c;
      }
    '';
  };

  xdg.configFile."hypr/scripts/nightlight.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      SHADER="$HOME/.config/hypr/shaders/nightlight.glsl"
      is_on() { hyprctl getoption decoration:screen_shader 2>/dev/null | grep -q "$SHADER"; }
      on()  { hyprctl eval "hl.config({decoration = { screen_shader = \"$SHADER\" }})" >/dev/null; }
      off() { hyprctl eval 'hl.config({decoration = { screen_shader = "" }})' >/dev/null; }
      case "''${1:-toggle}" in
          status)
              if is_on; then
                  printf '{"text": "\\uf186", "class": "on", "tooltip": "night light on — click to turn off"}\n'
              else
                  printf '{"text": "\\uf185", "class": "off", "tooltip": "night light off — click to turn on"}\n'
              fi ;;
          on)  on ;;
          off) off ;;
          *)
              if is_on; then
                  off
                  notify-send "Night light" "off" 2>/dev/null || true
              else
                  on
                  notify-send "Night light" "on" 2>/dev/null || true
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
      # setsid + full fd detach, same reason as nightlight: an inherited
      # pipe held open by the daemon can hang SwayNC's click handler.
      on()  { pgrep -f 'why=caffeine' >/dev/null || \
              setsid ${pkgs.systemd}/bin/systemd-inhibit --what=idle:shutdown:sleep \
                  --why=caffeine --who=caffeine --mode=block \
                  sleep infinity </dev/null >/dev/null 2>&1 & }
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

  # ─── Clock: time on the pill, date in the tooltip ──────────────────
  # Russian day/month names are hardcoded (en_US is the default locale;
  # ru_RU exists too, but these tables don't depend on locale tooling):
  # text "10:15", tooltip "12 октября, понедельник".
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
      printf '{"text":"%s","tooltip":"%s %s, %s"}\n' \
          "$(date +%H:%M)" "$(date +%-d)" "$m" "$w"
    '';
  };

  # ─── Weather (waybar module, wttr.in j1) ────────────────────────────
  # Bar: emoji + current temp. Tooltip: now / today (min…max + condition
  # at midday) / rain chance / wind — all in Russian.
  xdg.configFile."hypr/scripts/weather.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      json=$(curl -s --max-time 8 'wttr.in/?format=j1&lang=ru' 2>/dev/null)
      [ -n "$json" ] || { echo '{"text":""}'; exit 0; }
      printf '%s' "$json" | ${pkgs.jq}/bin/jq -r '
        def emoji($c):
          if $c == "113" then "☀️"
          elif $c == "116" then "⛅"
          elif ($c | test("^(119|122)$")) then "☁️"
          elif ($c | test("^(143|248|260)$")) then "🌫️"
          elif ($c | test("^(200|386|389|392)$")) then "⛈️"
          elif ($c | test("^(179|227|230|320|323|326|329|332|335|338|350|368|371|374|377|395)$")) then "🌨️"
          elif ($c | test("^(176|353|362)$")) then "🌦️"
          elif ($c | test("^(185|263|266|281|284|293|296|299|302|305|307|308|311|314|315|317|318|356|359|365|399)$")) then "🌧️"
          else "🌡️" end;
        (.current_condition[0]) as $c |
        (.weather[0]) as $w |
        ($w.hourly[4]) as $mid |
        ($mid.lang_ru[0].value // $mid.weatherDesc[0].value // "?") as $wdesc |
        ($c.lang_ru[0].value // $c.weatherDesc[0].value // "?") as $cdesc |
        ([$w.hourly[].chanceofrain | tonumber] | max) as $rain |
        ($mid.windspeedKmph // $c.windspeedKmph) as $wind |
        {
          text: "\(emoji($c.weatherCode)) \($c.temp_C)°",
          tooltip: "Сейчас: \($c.temp_C)°, \($cdesc)\nСегодня: \($w.mintempC)…\($w.maxtempC)°, \($wdesc)\nДождь: \($rain)% · Ветер: \($wind) км/ч"
        } | @json' 2>/dev/null || echo '{"text":""}'
    '';
  };

  # ─── codebase-memory-mcp daemon (warm index + file watcher) ─────────
  # Keeps the per-project code graph warm so MCP servers, CLI calls and
  # prompt hooks skip the ~2s binary startup. Binary itself lives in
  # ~/.local/bin (portable release; not nix-managed).
  systemd.user.services.cbm-daemon = {
    Unit.Description = "codebase-memory-mcp daemon (warm index + file watcher)";
    Service = {
      ExecStart = "%h/.local/bin/codebase-memory-mcp --cbm-daemon-internal --cbm-daemon-permanent";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
