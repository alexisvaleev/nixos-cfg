# Hyprland configuration (Lua format, 0.55+) + screenshot helper script.
{ config, pkgs, lib, ... }:
let
  theme = import ./theme.nix;
in
{
  # ─── Hyprland Lua config ───────────────────────────────────────────
  xdg.configFile."hypr/hyprland.lua" = {
    force = true;
    text = ''
    -- blessed's Hyprland config (managed by Home Manager)

    ------------------
    ---- MONITORS ----
    ------------------
    -- Rules are matched by EDID description so they stick to the physical
    -- display, not the port — this SSD boots on several machines.

    -- Desktop PC: HKM N2788HZ 27" 1440p @ 165Hz, VRR (VRR needs the
    -- proprietary NVIDIA driver; nouveau ignores the flag — harmless).
    hl.monitor({ output = "desc:HKM N2788HZ 0000000000001", mode = "2560x1440@165Hz", position = "0x0", scale = 1.0, vrr = 1 })
    -- ... and its Samsung 4K TV stays connected but unused.
    hl.monitor({ output = "desc:Samsung Electric Company SAMSUNG 0x01000E00", disabled = true })

    -- Second PC: two LG UltraGear, both at 1080p — the HDMI port can't do
    -- 4K@60, so 1080p@240/120 is the usable mode. 240Hz panel on the left.
    hl.monitor({ output = "desc:LG Electronics LG ULTRAGEAR 0x00056F29", mode = "1920x1080@240Hz", position = "0x0", scale = 1.0, vrr = 1 })
    hl.monitor({ output = "desc:LG Electronics LG ULTRAGEAR 0x00056F2B", mode = "1920x1080@120Hz", position = "1920x0", scale = 1.0, vrr = 1 })

    -- Fallback for anything else.
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.0 })

    ---------------------
    ---- MY PROGRAMS ----
    ---------------------
    local terminal    = "kitty"
    local fileManager = "dolphin"
    local menu        = "rofi -show drun"
    local browser     = "firefox"
    local chat        = "Telegram"

    -------------------
    ---- AUTOSTART ----
    -------------------
    hl.on("hyprland.start", function()
        -- One wrapper script avoids the 50 ms Lua event guard, lets us
        -- control ordering, and gives us a log for debugging.
        hl.exec_cmd("~/.config/hypr/scripts/autostart.sh")
    end)

    -------------------------------
    ---- ENVIRONMENT VARIABLES ----
    -------------------------------
    hl.env("XCURSOR_SIZE", "18")
    hl.env("HYPRCURSOR_SIZE", "18")
    hl.env("QT_QPA_PLATFORM", "wayland")
    hl.env("XDG_SESSION_TYPE", "wayland")

    -----------------------
    ---- LOOK AND FEEL ----
    -----------------------
    local function load_colors()
        local path = "${config.home.homeDirectory}/.config/theme/colors.lua"
        if dofile then
            local ok, c = pcall(dofile, path)
            if ok and type(c) == "table" then return c end
        end
        return {
            bg = "${theme.bg}", bg_dark = "${theme.bg_dark}",
            surface = "${theme.surface}", surface2 = "${theme.surface2}", surface3 = "${theme.surface3}",
            text = "${theme.text}", subtext = "${theme.subtext}", muted = "${theme.muted}",
            purple = "${theme.purple}", mauve = "${theme.mauve}", deep = "${theme.deep}",
            magenta = "${theme.magenta}", green = "${theme.green}", red = "${theme.red}",
            yellow = "${theme.yellow}", blue = "${theme.blue}", orange = "${theme.orange}", teal = "${theme.teal}",
            accent = "${theme.accent}", accent2 = "${theme.accent2}",
        }
    end
    local colors = load_colors()
    local function rgba(c, a) return "rgba(" .. (c:gsub("#","")) .. a .. ")" end

    hl.config({
        cursor = {
            -- HW cursors vanish when idle on nouveau AND i915; the same
            -- SSD boots on different machines, so just use software
            -- cursors everywhere — the perf cost is negligible.
            no_hardware_cursors = true,
        },
        general = {
            gaps_in  = 4,
            gaps_out = 16,
            border_size = 2,
            col = {
                active_border   = { colors = { rgba(colors.accent, "ee"), rgba(colors.deep, "ee") }, angle = 45 },
                inactive_border = rgba(colors.surface2, "aa"),
            },
            resize_on_border = true,
            hover_icon_on_border = true,
            resize_corner = 0,
            allow_tearing = false,
            layout = "dwindle",
        },

        decoration = {
            rounding       = 10,
            rounding_power = 2,
            active_opacity   = 1.0,
            inactive_opacity = 0.95,
            shadow = {
                enabled      = true,
                range        = 4,
                render_power = 3,
                color        = rgba(colors.bg, "ee"),
            },
            blur = {
                enabled   = true,
                size      = 3,
                passes    = 1,
                vibrancy  = 0.1696,
            },
        },

        animations = {
            enabled = true,
        },
    })

    -- curves
    hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
    hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
    hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
    hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
    hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
    hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

    hl.animation({ leaf = "global",        enabled = true,  speed = 8,    bezier = "default" })
    hl.animation({ leaf = "border",        enabled = true,  speed = 5,    bezier = "easeOutQuint" })
    hl.animation({ leaf = "windows",       enabled = true,  speed = 5,    bezier = "easeOutQuint", style = "popin 80%" })
    hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 5,    bezier = "easeOutQuint", style = "popin 80%" })
    hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "popin 80%" })
    hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.8,  bezier = "almostLinear" })
    hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.5,  bezier = "almostLinear" })
    hl.animation({ leaf = "fade",          enabled = true,  speed = 3,    bezier = "quick" })
    hl.animation({ leaf = "layers",        enabled = true,  speed = 4,    bezier = "easeOutQuint" })
    hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
    hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.6,  bezier = "linear",       style = "fade" })
    hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.8,  bezier = "almostLinear" })
    hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.4,  bezier = "almostLinear" })
    hl.animation({ leaf = "workspaces",    enabled = true,  speed = 2,    bezier = "almostLinear", style = "slidefade 20%" })
    hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.4,  bezier = "almostLinear", style = "slidefade 20%" })
    hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 2,    bezier = "almostLinear", style = "slidefade 20%" })
    hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5,  bezier = "easeOutQuint", style = "slidefadevert 20%" })
    hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

    ------------------
    ----  LAYOUTS ----
    ------------------
    hl.config({
        dwindle = { preserve_split = true },
        master  = { new_status = "master" },
        scrolling = { fullscreen_on_one_column = true },
    })

    ---------------
    ----  MISC ----
    ---------------
    hl.config({
        misc = {
            force_default_wallpaper = -1,
            disable_hyprland_logo   = false,
            # honour activation requests: clicking a Telegram (or any)
            # notification jumps to that app's workspace + window
            focus_on_activate = true,
        },
    })

    ---------------
    ---- INPUT ----
    ---------------
    hl.config({
        input = {
            kb_layout  = "us,ru",
            kb_variant = ",winkeys",
            kb_model   = "",
            kb_options = "grp:win_space_toggle",
            kb_rules   = "",
            follow_mouse = 1,
            sensitivity = 0,
            touchpad = { natural_scroll = true },
        },
    })

    hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

    ---------------------
    ---- KEYBINDINGS ----
    ---------------------
    local mainMod = "SUPER"

    -- launchers / windows
    hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
    hl.bind(mainMod .. " + C", hl.dsp.window.close())
    hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
    hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
    hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
    hl.bind(mainMod .. " + P",        hl.dsp.exec_cmd("~/.config/rofi/powermenu.sh"))
    hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pseudo())
    hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
    hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
    hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

    -- applications
    hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(browser))
    hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(chat))

    -- focus
    hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left"  }))
    hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
    hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up"    }))
    hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down"  }))

    -- move active window in a direction
    hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left"  }))
    hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
    hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up"    }))
    hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down"  }))

    -- cycle workspaces
    hl.bind(mainMod .. " + Tab",       hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace.sh next"))
    hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace.sh prev"))

    -- workspaces 1-10
    for i = 1, 10 do
        local key = i % 10
        hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
        hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    end

    -- special workspace (scratchpad)
    hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))

    -- rofi menus
    hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("rofi -show window"))
    hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("~/.config/rofi/powermenu.sh"))

    -- control center (SwayNC)
    hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("${pkgs.swaynotificationcenter}/bin/swaync-client -t"))
    hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw"))

    -- clipboard history + emoji picker + wallpaper picker
    hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("~/.config/hypr/scripts/clipboard.sh"))
    hl.bind(mainMod .. " + period",    hl.dsp.exec_cmd("${pkgs.rofimoji}/bin/rofimoji"))
    hl.bind(mainMod .. " + CTRL + W",  hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper.sh --pick"))
    hl.bind(mainMod .. " + ALT + W",   hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper.sh"))
    hl.bind(mainMod .. " + CTRL + T",  hl.dsp.exec_cmd("~/.config/hypr/scripts/waybar-tune"))

    -- extras: keybind cheatsheet, night light, screen record, mixer
    hl.bind(mainMod .. " + slash",        hl.dsp.exec_cmd("~/.config/hypr/scripts/cheatsheet.sh"))
    hl.bind(mainMod .. " + SHIFT + N",    hl.dsp.exec_cmd("~/.config/hypr/scripts/nightlight.sh"))
    hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/record.sh"))
    hl.bind(mainMod .. " + ALT + V",      hl.dsp.exec_cmd("${pkgs.pwvucontrol}/bin/pwvucontrol"))

    -- screenshots (grim + slurp; swappy annotator on SUPER+ALT+S only)
    hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh area-clip"))
    hl.bind(mainMod .. " + ALT + S",   hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh swappy"))
    hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh full-clip"))
    hl.bind("Print",                   hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh area-clip"))
    hl.bind("CTRL + Print",            hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh full-file"))

    -- lock
    hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

    -- switch workspaces (creates new if needed)
    hl.bind("CTRL + ALT + right", hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace.sh next"))
    hl.bind("CTRL + ALT + left",  hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace.sh prev"))
    hl.bind("CTRL + ALT + down",  hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace.sh next"))
    hl.bind("CTRL + ALT + up",    hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace.sh prev"))

    -- move active window to workspace and follow
    hl.bind("CTRL + ALT + SHIFT + right", hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace.sh movenext"))
    hl.bind("CTRL + ALT + SHIFT + left",  hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace.sh moveprev"))
    hl.bind("CTRL + ALT + SHIFT + down",  hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace.sh movenext"))
    hl.bind("CTRL + ALT + SHIFT + up",    hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace.sh moveprev"))

    -- scroll through workspaces
    hl.bind(mainMod .. " + mouse_down", hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace.sh next"))
    hl.bind(mainMod .. " + mouse_up",   hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace.sh prev"))

    -- move/resize windows with the mouse
    hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
    hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    -- media keys: swayosd gives an OSD overlay for volume/brightness/media.
    hl.bind("XF86AudioRaiseVolume",   hl.dsp.exec_cmd("${pkgs.swayosd}/bin/swayosd-client --output-volume raise"),        { locked = true, repeating = true })
    hl.bind("XF86AudioLowerVolume",   hl.dsp.exec_cmd("${pkgs.swayosd}/bin/swayosd-client --output-volume lower"),        { locked = true, repeating = true })
    hl.bind("XF86AudioMute",          hl.dsp.exec_cmd("${pkgs.swayosd}/bin/swayosd-client --output-volume mute-toggle"),   { locked = true })
    hl.bind("XF86AudioMicMute",       hl.dsp.exec_cmd("${pkgs.swayosd}/bin/swayosd-client --input-volume mute-toggle"),   { locked = true })
    hl.bind("XF86MonBrightnessUp",    hl.dsp.exec_cmd("${pkgs.swayosd}/bin/swayosd-client --brightness raise"),            { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown",  hl.dsp.exec_cmd("${pkgs.swayosd}/bin/swayosd-client --brightness lower"),            { locked = true, repeating = true })
    hl.bind("XF86AudioNext",          hl.dsp.exec_cmd("${pkgs.swayosd}/bin/swayosd-client --playerctl next"),              { locked = true })
    hl.bind("XF86AudioPause",         hl.dsp.exec_cmd("${pkgs.swayosd}/bin/swayosd-client --playerctl play-pause"),        { locked = true })
    hl.bind("XF86AudioPlay",          hl.dsp.exec_cmd("${pkgs.swayosd}/bin/swayosd-client --playerctl play-pause"),        { locked = true })
    hl.bind("XF86AudioPrev",          hl.dsp.exec_cmd("${pkgs.swayosd}/bin/swayosd-client --playerctl prev"),              { locked = true })

    --------------------------------
    ---- WINDOWS AND WORKSPACES ----
    --------------------------------
    hl.window_rule({
        name  = "suppress-maximize-events",
        match = { class = ".*" },
        suppress_event = "maximize",
    })

    hl.window_rule({
        name  = "fix-xwayland-drags",
        match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
        no_focus = true,
    })

    hl.window_rule({
        name  = "rofi-float",
        match = { class = "^rofi$" },
        float = true,
    })

    -- Floating utility windows opened from keybinds/waybar.
    hl.window_rule({
        name  = "mixer-float",
        match = { class = "pwvucontrol" },
        float = true, size = "60% 70%", center = true,
    })
    hl.window_rule({
        name  = "btop-float",
        match = { class = "btop-float" },
        float = true, size = "70% 80%", center = true,
    })

    hl.window_rule({
        name  = "telegram-opacity",
        match = { class = "org.telegram.desktop" },
        opacity = 0.95,
    })

    -- Telegram requests activation on every incoming message, which with
    -- focus_on_activate would yank focus on arrival. Suppress it; clicks
    -- on its notifications are handled by notify-click-jump.py instead.
    hl.window_rule({
        name  = "telegram-suppress-activate",
        match = { class = "org.telegram.desktop" },
        suppress_event = "activate",
    })

    -- Frosted glass blur for the macOS-style Waybar layer.
    hl.layer_rule({
        match = { namespace = "^waybar$" },
        blur = true,
        ignore_alpha = 0.2,
    })

    '';
  };

  # ─── Autostart wrapper ─────────────────────────────────────────────
  # hyprland.start has a ~50 ms Lua guard, and some daemons need the
  # logind session / D-Bus to be fully ready.  A small bash script lets
  # us start them in the right order with a short delay and a log.
  xdg.configFile."hypr/scripts/autostart.sh" = {
    force = true;
    executable = true;
    text = ''
      #!/usr/bin/env bash
      LOG=/tmp/hypr-autostart.log
      >> "$LOG"
      exec >>"$LOG" 2>&1
      echo "[$(date +%Y-%m-%d\ %H:%M:%S)] autostart begin"

      # Wallpaper first: hyprpaper must be up before wallpaper.sh sets it.
      nohup hyprpaper                           >/dev/null 2>&1 &
      sleep 0.5
      ~/.config/hypr/scripts/wallpaper.sh --init >/dev/null 2>&1

      # Kill any stray notification daemon before swaync grabs the name.
      pkill -f 'mako|dunst' 2>/dev/null || true

      # The hyprland portal dbus-activates before the session env reaches
      # systemd, crash-loops on "couldn't connect to a wayland
      # compositor", hits start-limit and stays dead -> no screen share.
      # Restart it once the compositor is guaranteed to be up.
      ( systemctl --user reset-failed xdg-desktop-portal-hyprland
        sleep 1
        systemctl --user restart xdg-desktop-portal-hyprland
      ) >/dev/null 2>&1 &

      # Then the rest of the desktop.
      pgrep -f 'waybar-wrapped' >/dev/null 2>&1 || \
          nohup waybar                          >/dev/null 2>&1 &
      nohup ~/.config/hypr/scripts/sni-fixer.sh >/dev/null 2>&1 &
      nohup nm-applet --indicator               >/dev/null 2>&1 &
      nohup GSK_RENDERER=cairo ${pkgs.swaynotificationcenter}/bin/swaync >/dev/null 2>&1 &
      # GDK_BACKEND=wayland: without it GTK can silently fall back to
      # X11 when started early in the session, and the OSD then opens as
      # huge tiled xwayland windows instead of a layer-shell overlay.
      nohup env GDK_BACKEND=wayland ${pkgs.swayosd}/bin/swayosd-server >/dev/null 2>&1 &
      # Quickshell player popup (hidden until the waybar click toggles it).
      nohup ${pkgs.quickshell}/bin/qs -c player >/dev/null 2>&1 &
      nohup wl-paste --type text  --watch ${pkgs.cliphist}/bin/cliphist store >/dev/null 2>&1 &
      nohup wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store >/dev/null 2>&1 &
      # Notification click-jumper for activation-suppressed apps (Telegram).
      pgrep -f 'notify-click-jump.py' >/dev/null 2>&1 || \
          nohup ${pkgs.python3}/bin/python3 "$HOME/.local/bin/notify-click-jump.py" >/dev/null 2>&1 &
      nohup ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 >/dev/null 2>&1 &
      # Proxy helpers. v2rayN lives in the HM profile; TgWsProxy is a
      # hand-managed PyInstaller binary in ~/.local/bin which is NOT on
      # the session PATH — so use absolute paths and pgrep guards.
      pgrep -x v2rayN >/dev/null 2>&1 || \
          nohup ${pkgs.v2rayn}/bin/v2rayN         >/dev/null 2>&1 &
      if [ -x "$HOME/.local/bin/TgWsProxy" ]; then
          pgrep -f 'TgWsProxy-bin' >/dev/null 2>&1 || \
              nohup "$HOME/.local/bin/TgWsProxy"  >/dev/null 2>&1 &
      fi



      # hypridle needs the logind session to be registered, which happens
      # slightly after Hyprland is fully up.  Wait a bit, start it, then
      # give it a moment to connect to the session-lock notify protocol
      # before we trigger the initial lock.
      (
          sleep 2
          nohup hypridle >/tmp/hypridle-autostart.log 2>&1 &

          # Wait for hypridle to actually be running (up to ~2s).
          for i in 1 2 3 4; do
              sleep 0.5
              pidof hypridle >/dev/null 2>&1 && break
          done

          # Lock once.  The pidof guard prevents re-locking on reload.
          if ! pidof hyprlock >/dev/null 2>&1; then
              nohup hyprlock >/tmp/hyprlock-autostart.log 2>&1 &
          fi
      ) &

      echo "[$(date +%Y-%m-%d\ %H:%M:%S)] autostart dispatch done"
    '';
  };

  # ─── SNI orphan fixer ──────────────────────────────────────────────
  # waybar's tray only shows apps that registered themselves with the
  # StatusNotifierWatcher. v2rayN owns a StatusNotifierItem bus name but
  # never calls RegisterStatusNotifierItem, so its icon never appears —
  # and any waybar restart orphans every such item again. This loop finds
  # unregistered SNI names on the bus and registers them with whatever
  # watcher is currently live.
  xdg.configFile."hypr/scripts/sni-fixer.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # NOTE: busctl ships with systemd — pkgs.dbus has no busctl, so the
      # old pin pointed at a nonexistent store path and every call failed
      # silently (the fixer looped forever doing nothing).
      BUSCTL=${pkgs.systemd}/bin/busctl
      LOG=/tmp/sni-fixer.log

      while true; do
          items=$($BUSCTL --user get-property org.kde.StatusNotifierWatcher \
              /StatusNotifierWatcher org.kde.StatusNotifierWatcher \
              RegisteredStatusNotifierItems 2>/dev/null) || items=""
          $BUSCTL --user list 2>/dev/null \
              | awk '/^(org\.kde|org\.freedesktop)\.StatusNotifierItem-/ {print $1}' \
              | while read -r name; do
                  case "$items" in
                      *"$name"*) ;;
                      *) echo "$(date '+%F %T') re-register $name" >> "$LOG"
                         $BUSCTL --user call org.kde.StatusNotifierWatcher \
                          /StatusNotifierWatcher org.kde.StatusNotifierWatcher \
                          RegisterStatusNotifierItem s "$name" >>"$LOG" 2>&1 ;;
                  esac
              done
          sleep 10
      done
    '';
  };

  # ─── Screenshot helper script ──────────────────────────────────────
  xdg.configFile."hypr/scripts/screenshot.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -e
      shot_dir="$HOME/Pictures/Screenshots"
      case "$1" in
        swappy)
          grim -g "$(slurp)" - | swappy -f -
          ;;
        area-clip)
          grim -g "$(slurp)" - | wl-copy
          ;;
        full-clip)
          grim - | wl-copy
          ;;
        full-file)
          mkdir -p "$shot_dir"
          local file="$shot_dir/$(date +%Y%m%d_%H%M%S).png"
          grim "$file"
          notify-send "Screenshot saved" "$file" -i camera-photo
          ;;
        *)
          echo "usage: screenshot.sh {swappy|area-clip|full-clip|full-file}" >&2
          exit 1
          ;;
      esac
    '';
  };
}
