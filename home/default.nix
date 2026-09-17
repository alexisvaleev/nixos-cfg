# Home-manager entry point for user `blessed`.
{ config, pkgs, lib, inputs, ... }:

{
  home.username = "blessed";
  home.homeDirectory = "/home/blessed";
  home.stateVersion = "26.05";

  imports = [
    ./modules/shell.nix
    ./modules/terminal.nix
    ./modules/hyprland.nix
    ./modules/waybar.nix
    ./modules/launcher.nix
    ./modules/swaync.nix
    ./modules/lockscreen.nix
    ./modules/wallpaper.nix
    ./modules/fastfetch.nix
    ./modules/apps.nix
    ./modules/matugen.nix
    ./modules/icons-cursor.nix
    ./modules/osd.nix
    ./modules/extras.nix
  ];

  # small extra CLI utilities
  home.packages = with pkgs; [
    eza
    fzf
    bat
    zoxide
    jq
    xdg-utils
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # XDG user dirs
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    pictures = "${config.home.homeDirectory}/Pictures";
  };

  # Use a stable location for the wallpaper so hyprpaper/hyprlock can find it.
  # The actual image is placed by wallpaper.nix into ~/.local/share/backgrounds/.
  home.sessionVariables = {
    XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
  };
}
