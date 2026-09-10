# hyprlock (screen lock) + hypridle (idle daemon).
# hyprlock config via the HM module (config-only, no systemd unit).
# hypridle via raw config (started through hyprland.lua autostart).
{ config, pkgs, lib, ... }:
let
  theme = import ./theme.nix;
  wall = "${config.home.homeDirectory}/.local/share/backgrounds/wallpaper.jpg";
in
{
  programs.hyprlock = {
    enable = true;
    settings = with theme; {
      general = {
        hide_cursor = true;
        ignore_empty_input = true;
      };

      background = [
        {
          monitor = "";
          path = wall;
          blur_passes = 3;
          blur_size = 8;
          brightness = 0.5;
        }
      ];

      label = [
        {
          monitor = "";
          text = "cmd[update:1000] echo \"$(date +'%H:%M')\"";
          color = text;
          font_size = 96;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 120";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "cmd[update:1000] echo \"$(date +'%A, %d %B')\"";
          color = subtext;
          font_size = 22;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 40";
          halign = "center";
          valign = "center";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "300, 50";
          outline_thickness = 2;
          dots_center = true;
          fade_on_empty = false;
          placeholder_text = "Enter password...";
          hide_input = false;
          position = "0, -80";
          halign = "center";
          valign = "center";
          font_family = "JetBrainsMono Nerd Font";
          font_color = text;
          inner_color = surface;
          outer_color = purple;
          check_color = blue;
          fail_color = red;
          capslock_color = yellow;
        }
      ];
    };
  };

  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
        after_sleep_cmd = hyprctl dispatch 'hl.dsp.dpms({action="on"})'
        before_sleep_cmd = hyprlock
        ignore_dbus_inhibit = false
        lock_cmd = pidof hyprlock || hyprlock
    }

    listener {
        timeout = 600
        on-timeout = hyprlock
        ignore_inhibit = true
    }

    listener {
        timeout = 900
        on-timeout = hyprctl dispatch 'hl.dsp.dpms({action="off"})'
        on-resume = hyprctl dispatch 'hl.dsp.dpms({action="on"})'
    }
  '';
}
