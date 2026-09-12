# matugen — dynamic Material You palette generation from wallpaper.
# Generates ~/.config/theme/colors.css / colors.lua / colors.json / colors.conf
# that Hyprland, Waybar, SwayNC and hyprlock read at runtime.
{ config, pkgs, ... }:
let
  home = config.home.homeDirectory;
in
{
  home.packages = [ pkgs.matugen ];

  xdg.configFile."matugen/config.toml".text = ''
    [config]
    mode = "dark"

    # Custom accent colors blended with the generated palette so the theme
    # keeps its Graphite+Purple character regardless of wallpaper.
    [config.custom_colors]
    purple  = { color = "#a78bfa", blend = true }
    mauve   = { color = "#c4b5fd", blend = true }
    deep    = { color = "#7c3aed", blend = true }
    magenta = { color = "#d946ef", blend = true }
    green   = { color = "#4ade80", blend = true }
    red     = { color = "#f472b6", blend = true }
    yellow  = { color = "#facc15", blend = true }
    blue    = { color = "#60a5fa", blend = true }
    orange  = { color = "#fb923c", blend = true }
    teal    = { color = "#2dd4bf", blend = true }

    [templates]
    colors_css  = { input_path = "${home}/.config/matugen/templates/colors.css.tmpl",  output_path = "${home}/.config/theme/colors.css"  }
    colors_lua  = { input_path = "${home}/.config/matugen/templates/colors.lua.tmpl",  output_path = "${home}/.config/theme/colors.lua"  }
    colors_json = { input_path = "${home}/.config/matugen/templates/colors.json.tmpl", output_path = "${home}/.config/theme/colors.json" }
    colors_conf = { input_path = "${home}/.config/matugen/templates/colors.conf.tmpl", output_path = "${home}/.config/theme/colors.conf" }
  '';

  xdg.configFile."matugen/templates/colors.css.tmpl".text = ''
    @define-color bg {{colors.background.default.hex}};
    @define-color bg_dark {{colors.surface_dim.default.hex}};
    @define-color surface {{colors.surface.default.hex}};
    @define-color surface2 {{colors.surface_variant.default.hex}};
    @define-color surface3 {{colors.surface_container_highest.default.hex}};
    @define-color text {{colors.on_background.default.hex}};
    @define-color subtext {{colors.on_surface_variant.default.hex}};
    @define-color muted {{colors.outline.default.hex}};
    @define-color purple {{colors.purple.default.hex}};
    @define-color mauve {{colors.mauve.default.hex}};
    @define-color deep {{colors.deep.default.hex}};
    @define-color magenta {{colors.magenta.default.hex}};
    @define-color green {{colors.green.default.hex}};
    @define-color red {{colors.red.default.hex}};
    @define-color yellow {{colors.yellow.default.hex}};
    @define-color blue {{colors.blue.default.hex}};
    @define-color orange {{colors.orange.default.hex}};
    @define-color teal {{colors.teal.default.hex}};
    @define-color accent {{colors.purple.default.hex}};
    @define-color accent2 {{colors.mauve.default.hex}};
  '';

  xdg.configFile."matugen/templates/colors.lua.tmpl".text = ''
    return {
      bg = "{{colors.background.default.hex}}",
      bg_dark = "{{colors.surface_dim.default.hex}}",
      surface = "{{colors.surface.default.hex}}",
      surface2 = "{{colors.surface_variant.default.hex}}",
      surface3 = "{{colors.surface_container_highest.default.hex}}",
      text = "{{colors.on_background.default.hex}}",
      subtext = "{{colors.on_surface_variant.default.hex}}",
      muted = "{{colors.outline.default.hex}}",
      purple = "{{colors.purple.default.hex}}",
      mauve = "{{colors.mauve.default.hex}}",
      deep = "{{colors.deep.default.hex}}",
      magenta = "{{colors.magenta.default.hex}}",
      green = "{{colors.green.default.hex}}",
      red = "{{colors.red.default.hex}}",
      yellow = "{{colors.yellow.default.hex}}",
      blue = "{{colors.blue.default.hex}}",
      orange = "{{colors.orange.default.hex}}",
      teal = "{{colors.teal.default.hex}}",
      accent = "{{colors.purple.default.hex}}",
      accent2 = "{{colors.mauve.default.hex}}",
    }
  '';

  xdg.configFile."matugen/templates/colors.json.tmpl".text = ''
    {
      "bg": "{{colors.background.default.hex}}",
      "bg_dark": "{{colors.surface_dim.default.hex}}",
      "surface": "{{colors.surface.default.hex}}",
      "surface2": "{{colors.surface_variant.default.hex}}",
      "surface3": "{{colors.surface_container_highest.default.hex}}",
      "text": "{{colors.on_background.default.hex}}",
      "subtext": "{{colors.on_surface_variant.default.hex}}",
      "muted": "{{colors.outline.default.hex}}",
      "purple": "{{colors.purple.default.hex}}",
      "mauve": "{{colors.mauve.default.hex}}",
      "deep": "{{colors.deep.default.hex}}",
      "magenta": "{{colors.magenta.default.hex}}",
      "green": "{{colors.green.default.hex}}",
      "red": "{{colors.red.default.hex}}",
      "yellow": "{{colors.yellow.default.hex}}",
      "blue": "{{colors.blue.default.hex}}",
      "orange": "{{colors.orange.default.hex}}",
      "teal": "{{colors.teal.default.hex}}",
      "accent": "{{colors.purple.default.hex}}",
      "accent2": "{{colors.mauve.default.hex}}"
    }
  '';

  xdg.configFile."matugen/templates/colors.conf.tmpl".text = ''
    $bg = {{colors.background.default.rgb}}
    $bg_dark = {{colors.surface_dim.default.rgb}}
    $surface = {{colors.surface.default.rgb}}
    $surface2 = {{colors.surface_variant.default.rgb}}
    $surface3 = {{colors.surface_container_highest.default.rgb}}
    $text = {{colors.on_background.default.rgb}}
    $subtext = {{colors.on_surface_variant.default.rgb}}
    $muted = {{colors.outline.default.rgb}}
    $purple = {{colors.purple.default.rgb}}
    $mauve = {{colors.mauve.default.rgb}}
    $deep = {{colors.deep.default.rgb}}
    $magenta = {{colors.magenta.default.rgb}}
    $green = {{colors.green.default.rgb}}
    $red = {{colors.red.default.rgb}}
    $yellow = {{colors.yellow.default.rgb}}
    $blue = {{colors.blue.default.rgb}}
    $orange = {{colors.orange.default.rgb}}
    $teal = {{colors.teal.default.rgb}}
    $accent = {{colors.purple.default.rgb}}
    $accent2 = {{colors.mauve.default.rgb}}
  '';
}
