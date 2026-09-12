# Graphite + Purple design tokens.
# Imported by other modules: `let theme = import ./theme.nix; in ...`
{
  bg       = "#0f0f15";
  bg_dark  = "#0a0a10";
  surface  = "#18181f";
  surface2 = "#22222b";
  surface3 = "#2a2a35";
  text     = "#e6e6f0";
  subtext  = "#a0a0b0";
  muted    = "#6b6b7a";

  purple   = "#a78bfa";
  mauve    = "#c4b5fd";
  deep     = "#7c3aed";
  magenta  = "#d946ef";
  green    = "#34d399";
  red      = "#f87171";
  yellow   = "#facc15";
  blue     = "#60a5fa";
  orange   = "#fb923c";
  teal     = "#2dd4bf";

  accent   = "#a78bfa";
  accent2  = "#c4b5fd";

  # rgba helpers (for hyprland / hyprlock which want 0xRRGGBBAA or rgba())
  bg0      = "0xee0f0f15";
  surface0 = "0xee18181f";
  purple0  = "0xffa78bfa";
  deep0    = "0xff7c3aed";
}
