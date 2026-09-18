# hyprpaper — wallpaper daemon (raw config; started via hyprland.lua).
# The wallpaper image is installed into a stable location below.
# wallpaper.sh picks a random wallpaper from ~/Pictures/wallpapers, applies it
# via hyprpaper, then regenerates the theme with matugen and reloads consumers.
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
    wallpaper=eDP-1,${wall}
  '';

  # Stable wallpaper location, used by hyprpaper + hyprlock.
  xdg.dataFile."backgrounds/wallpaper.jpg".source = ../../assets/wallpaper.jpg;

  # Auto-rotate: every 30 min pick a random image from
  # ~/Pictures/wallpapers, apply it and regenerate the matugen palette.
  # With one file it just re-applies the same wallpaper — drop more
  # images into the dir to make rotation meaningful.
  systemd.user.services.wallpaper-rotate = {
    Unit.Description = "Rotate wallpaper + matugen theme";
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.config/hypr/scripts/wallpaper.sh";
    };
  };

  systemd.user.timers.wallpaper-rotate = {
    Unit.Description = "Periodic wallpaper rotation";
    Timer = {
      OnBootSec = "10min";
      OnUnitActiveSec = "30min";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

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
          file="$DEFAULT_WALL"
      elif [ "''${1:-}" = "--pick" ]; then
          # rofi -dmenu with icon protocol: "label\0icon\x1f/path"
          choice=$(find "$WALL_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort | while IFS= read -r f; do
              printf '%s\0icon\x1f%s\n' "$(basename "$f")" "$f"
          done | rofi -dmenu -show-icons -i -p "Wallpaper" || true)
          choice="''${choice%%$'\0'*}"
          [ -n "$choice" ] || exit 0
          file=$(find "$WALL_DIR" -type f -name "$choice" 2>/dev/null | head -n1 || true)
          [ -n "$file" ] || exit 0
      else
          file=$(find "$WALL_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | shuf -n 1 || true)
          [ -n "$file" ] || file="$DEFAULT_WALL"
      fi

      [ -f "$file" ] || exit 0

      # Keep the stable path in sync so hyprlock/hyprpaper.conf still work.
      ln -sf "$file" "$DEFAULT_WALL"

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
