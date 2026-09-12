# SwayOSD — on-screen display for volume/brightness/media.
# Clipboard history via cliphist + rofi. Emoji via rofimoji.
{ config, pkgs, ... }:
let
  home = config.home.homeDirectory;
in
{
  home.packages = with pkgs; [
    swayosd
    cliphist
    rofimoji
  ];

  xdg.configFile."swayosd/style.css".text = ''
    @import "${home}/.config/theme/colors.css";

    window#osd {
      background: alpha(@bg, 0.95);
      border: 1px solid alpha(@purple, 0.2);
      border-radius: 14px;
      box-shadow: 0 12px 38px alpha(@bg_dark, 0.5);
      color: @text;
      padding: 0;
    }

    window#osd #container {
      margin: 12px 16px;
    }

    window#osd image {
      background: alpha(@purple, 0.12);
      border: 1px solid alpha(@purple, 0.22);
      border-radius: 10px;
      color: @mauve;
      min-width: 24px;
      min-height: 24px;
      padding: 6px;
      margin-right: 12px;
    }

    window#osd label {
      color: @text;
      font-family: "Iosevka Nerd Font Propo", "JetBrainsMono Nerd Font", "Symbols Nerd Font Mono", sans-serif;
      font-size: 13px;
      font-weight: 700;
      margin-left: 10px;
    }

    window#osd progressbar,
    window#osd segmentedprogress {
      min-width: 190px;
      min-height: 8px;
      border-radius: 999px;
    }

    window#osd trough,
    window#osd segment {
      background: alpha(@surface2, 0.8);
      border-radius: 999px;
      min-height: 8px;
    }

    window#osd progress,
    window#osd segment.active {
      background: @purple;
      border-radius: 999px;
      min-height: 8px;
    }
  '';

  xdg.configFile."hypr/scripts/clipboard.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -e
      choice=$(${pkgs.cliphist}/bin/cliphist list | rofi -dmenu -i -p "Clipboard" || true)
      [ -n "$choice" ] || exit 0
      printf '%s' "$choice" | ${pkgs.cliphist}/bin/cliphist decode | wl-copy
      notify-send "Clipboard" "Copied: $(printf '%s' "$choice" | head -c 60)…" 2>/dev/null || true
    '';
  };
}
