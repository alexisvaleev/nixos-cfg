# hyprpaper — wallpaper daemon (raw config; started via hyprland.lua).
# The wallpaper image is installed into a stable location below.
{ config, ... }:
let
  wall = "${config.home.homeDirectory}/.local/share/backgrounds/wallpaper.jpg";
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
}
