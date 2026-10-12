# Rofi (drun + window launcher) + power menu
{ config, pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;          # rofi 2.x — native Wayland support
    terminal = "kitty";
    theme = ./rofi-theme.rasi;

    extraConfig = {
      modi = "drun,window,run";
      show-icons = true;
      icon-theme = "Papirus-Dark";
      drun-display-format = "{name}";
      window-format = "{w}  ·  {c}  ·  {t}";
      display-drun = "Apps";
      display-window = "Windows";
      display-run = "Run";
      sidebar-mode = true;
      cycle = true;
      matching = "fuzzy";
      sort = true;
      scroll-method = 0;
    };
  };

  # ─── Power menu script (rofi -dmenu) ──────────────────────────────
  xdg.configFile."rofi/powermenu.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      options="Lock\nLogout\nSuspend\nReboot\nShutdown"
      chosen=$(printf "%b" "$options" | rofi -dmenu -p "Power" -i \
        -theme-str 'window { width: 280px; } listview { lines: 5; } inputbar { children: [ prompt ]; } entry { enabled: false; }')
      case "$chosen" in
        Lock)     hyprlock ;;
        Logout)   hyprctl dispatch 'hl.dsp.exit()' ;;
        Suspend)  systemctl suspend ;;
        Reboot)   systemctl reboot ;;
        Shutdown) systemctl poweroff ;;
      esac
    '';
  };

  # ─── networkmanager_dmenu: use rofi instead of plain dmenu ────────
  xdg.configFile."networkmanager-dmenu/config.ini".text = ''
    [dmenu]
    dmenu_command = rofi -dmenu -i -theme rofi-theme
    rofi_highlight = True
    compact = True
    wifi_chars = ▂▄▆█

    [dmenu_colors]
    separator = #6b6b7a
    foreground = #e6e6f0
    background = #0f0f15cc
    selected_background = #a78bfa
    selected_foreground = #0f0f15

    [dmenu_font]
    dmenu_font = JetBrainsMono Nerd Font 11
  '';
}
