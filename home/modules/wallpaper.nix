# hyprpaper — wallpaper daemon (raw config; started via hyprland.lua).
# The wallpaper image lives behind a stable symlink at
# ~/.local/share/backgrounds/wallpaper.jpg: whatever was last picked stays
# picked — across logins, reboots and every machine this config runs on.
# wallpaper.sh --pick (SUPER+CTRL+W) retargets the symlink, applies it via
# hyprpaper, regenerates the matugen theme and reloads consumers.
{ config, pkgs, ... }:
let
  home = config.home.homeDirectory;
  wall = "${home}/.local/share/backgrounds/wallpaper.jpg";
  matugen = "${pkgs.matugen}/bin/matugen";
in
{
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    ipc=on
    splash=false
    preload=${wall}
    wallpaper=,${wall}
  '';

  # Stable wallpaper location, used by hyprpaper + hyprlock. NOT managed
  # by HM: wallpaper.sh --init creates the symlink and later picks point
  # it at the chosen file — a managed link collides and aborts the whole
  # activation ("Existing file would be clobbered").

  xdg.configFile."hypr/scripts/wallpaper.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -e
      WALL_DIR="${home}/Pictures/wallpapers"
      THEME_DIR="${home}/.config/theme"
      DEFAULT_WALL="${wall}"
      mkdir -p "$THEME_DIR" "$WALL_DIR"

      if [ "''${1:-}" = "--init" ]; then
          # Login path: re-apply the persisted pick. The symlink survives
          # reboots, so whatever was last chosen is what comes back.
          file=$(readlink -f "$DEFAULT_WALL" 2>/dev/null || true)
          if [ ! -f "$file" ]; then
              # Nothing picked yet (or the target is gone): seed the link with
              # the bundled default, else any image we can find.
              file="$WALL_DIR/default.jpg"
              [ -f "$file" ] || file=$(find "$WALL_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort | head -n1 || true)
          fi
      elif [ "''${1:-}" = "--pick" ]; then
          # rofi is single-instance: a headless process left by an earlier
          # open holds the lock and every later launch exits silently before
          # a window can map. Pickers are modal anyway, so kill the stale one.
          pkill -x rofi 2>/dev/null || true
          # rofi -dmenu with icon protocol: "label\0icon\x1f/path"
          choice=$(find "$WALL_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort | while IFS= read -r f; do
              printf '%s\0icon\x1f%s\n' "$(basename "$f")" "$f"
          done | rofi -dmenu -show-icons -i -p "Wallpaper" || true)
          choice="''${choice%%$'\0'*}"
          [ -n "$choice" ] || exit 0
          file=$(find "$WALL_DIR" -type f -name "$choice" 2>/dev/null | head -n1 || true)
          [ -n "$file" ] || exit 0
      else
          # Manual random (SUPER+ALT+W): still a deliberate pick — it persists.
          file=$(find "$WALL_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | shuf -n 1 || true)
          [ -n "$file" ] || file="$WALL_DIR/default.jpg"
      fi

      [ -f "$file" ] || exit 0

      # Point the stable path at the pick so hyprlock/hyprpaper.conf follow.
      [ "$file" = "$DEFAULT_WALL" ] || ln -sf "$file" "$DEFAULT_WALL"

      # Apply wallpaper via hyprpaper (it's started by autostart.sh).
      hyprctl hyprpaper preload "$file" >/dev/null 2>&1 || true
      hyprctl hyprpaper wallpaper ",$file" >/dev/null 2>&1 || true
      hyprctl hyprpaper unload unused >/dev/null 2>&1 || true

      # Regenerate palette into ~/.config/theme/.
      ${matugen} image "$file" >/dev/null 2>&1 || ${matugen} color hex "#0f0f15" >/dev/null 2>&1 || true

      # Reload consumers.
      hyprctl reload >/dev/null 2>&1 || true
      if pidof waybar >/dev/null 2>&1; then
          # SIGUSR2 = reload CSS only. SIGUSR1 would TOGGLE the bar's
          # visibility and hide it — that was the "bar disappeared" bug.
          pkill -USR2 -f 'waybar-wrapped' 2>/dev/null || true
      fi
      if pidof swaync >/dev/null 2>&1; then
          swaync-client -R 2>/dev/null || pkill -HUP swaync >/dev/null 2>&1 || true
      fi
    '';
  };
}
