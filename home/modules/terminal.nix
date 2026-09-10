# Kitty terminal — graphite + purple theme
{ config, pkgs, lib, ... }:
let
  theme = import ./theme.nix;
in
{
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };

    settings = with theme; {
      # window
      background_opacity = "0.88";
      window_padding_width = "10";
      window_margin_width = "0";
      hide_window_decorations = "yes";
      confirm_os_window_close = "0";
      scrollback_lines = "10000";
      enable_audio_bell = false;
      cursor_shape = "beam";
      cursor_beam_thickness = "1.6";
      cursor_blink_interval = "0.5";
      mouse_hide_wait = "2.0";
      url_style = "curly";
      copy_on_select = "yes";
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      active_tab_foreground = "${bg}";
      active_tab_background = "${purple}";
      inactive_tab_foreground = "${text}";
      inactive_tab_background = "${surface2}";

      # base 16 colors
      foreground = "${text}";
      background = "${bg}";
      selection_foreground = "${bg}";
      selection_background = "${purple}";
      cursor = "${purple}";
      cursor_text_color = "${bg}";
      url_color = "${mauve}";

      color0 = "${surface2}";   # black
      color1 = "${red}";        # red
      color2 = "${green}";      # green
      color3 = "${yellow}";     # yellow
      color4 = "${blue}";       # blue
      color5 = "${purple}";     # magenta
      color6 = "${mauve}";      # cyan
      color7 = "${text}";       # white
      color8 = "${subtext}";    # bright black
      color9 = "${red}";        # bright red
      color10 = "${green}";     # bright green
      color11 = "${yellow}";    # bright yellow
      color12 = "${blue}";      # bright blue
      color13 = "${magenta}";   # bright magenta
      color14 = "${mauve}";     # bright cyan
      color15 = "${text}";      # bright white
    };

    keybindings = {
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+q" = "close_tab";
      "ctrl+shift+enter" = "new_window";
    };
  };
}
