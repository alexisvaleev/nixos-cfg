# Mako — notification daemon (raw config; started via hyprland.lua autostart).
{ ... }:
let
  theme = import ./theme.nix;
in
{
  xdg.configFile."mako/config".text = with theme; ''
    font=JetBrainsMono Nerd Font 10
    background-color=${surface}
    text-color=${text}
    border-color=${purple}
    border-size=2
    border-radius=10
    padding=10
    margin=10
    width=380
    height=120
    default-timeout=5000
    icons=1
    max-icon-size=48
    max-visible=5
    layer=overlay
    anchor=top-right
    sort=+time

    [urgency=high]
    border-color=${red}
    default-timeout=0

    [urgency=critical]
    border-color=${magenta}
    default-timeout=0
    background-color=${surface2}
  '';
}
