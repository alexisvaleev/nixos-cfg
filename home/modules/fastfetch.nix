# Fastfetch — system info shown on every new terminal.
# Config styled in the graphite + purple palette.
{ config, pkgs, ... }:
let
  theme = import ./theme.nix;
in
{
  xdg.configFile."fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
        "type": "builtin",
        "source": "nixos",
        "padding": {
          "top": 1,
          "right": 2
        }
      },
      "display": {
        "separator": " → ",
        "color": {
          "keys": "magenta",
          "title": "blue"
        }
      },
      "modules": [
        "title",
        "separator",
        {
          "type": "os",
          "key": "OS",
          "keyColor": "blue"
        },
        {
          "type": "kernel",
          "key": "Kernel",
          "keyColor": "blue"
        },
        {
          "type": "uptime",
          "key": "Uptime",
          "keyColor": "green"
        },
        {
          "type": "packages",
          "key": "Packages",
          "keyColor": "green"
        },
        {
          "type": "shell",
          "key": "Shell",
          "keyColor": "yellow"
        },
        {
          "type": "wm",
          "key": "WM",
          "keyColor": "magenta"
        },
        {
          "type": "terminal",
          "key": "Term",
          "keyColor": "magenta"
        },
        {
          "type": "cpu",
          "key": "CPU",
          "keyColor": "red"
        },
        {
          "type": "gpu",
          "key": "GPU",
          "keyColor": "red"
        },
        {
          "type": "memory",
          "key": "Memory",
          "keyColor": "green"
        },
        {
          "type": "disk",
          "key": "Disk",
          "keyColor": "green"
        },
        {
          "type": "battery",
          "key": "Battery",
          "keyColor": "yellow"
        },
        {
          "type": "locale",
          "key": "Locale",
          "keyColor": "blue"
        },
        "break",
        "colors"
      ]
    }
  '';
}
