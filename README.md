# blessed's NixOS + Hyprland rice

NixOS Flake with Home Manager for a declarative Hyprland desktop.

## What's inside

- **OS / session**: NixOS 26.05, Hyprland, SDDM auto-login with a custom theme
- **Top panel**: Waybar (macOS-style), with workspaces, active app, clock, volume, network, Bluetooth, battery, keyboard layout (EN/RU), tray and SwayNC control
- **Notifications**: SwayNotificationCenter with quick toggles, volume/backlight sliders, MPRIS and DND
- **Lock / idle**: hyprlock + hypridle, lock after 10 min idle, screen off after 15 min
- **Apps**: Firefox, Telegram, VSCode, Zed, Kitty, Dolphin, proxy tools (v2rayN/Xray/sing-box/mihomo)
- **Eye candy**: frosted-glass blur, custom GTK/Waybar/SwayNC purple/graphite theme

## Repository layout

```
.
├── flake.nix                 # entry point
├── flake.lock                # pinned inputs
├── hosts/
│   └── blessed/
│       ├── default.nix       # system config (hostname, user, services, packages)
│       ├── hardware.nix      # disk UUIDs / initrd modules — machine specific
│       └── sddm-theme.conf   # SDDM theme overrides
└── home/
    ├── default.nix           # home-manager entry point
    └── modules/              # waybar, swaync, hyprland, lockscreen, shell, apps, ...
```

## Quick start

1. Clone this repo to `~/.dotfiles`:

   ```bash
   git clone <your-github-url> ~/.dotfiles
   cd ~/.dotfiles
   ```

2. On a **new machine** regenerate `hosts/blessed/hardware.nix` to match your disks:

   ```bash
   sudo nixos-generate-config --root /mnt --show-hardware-config > hosts/blessed/hardware.nix
   ```

   If the host name changes, also adjust the flake output name in `flake.nix`.

3. Build and activate:

   ```bash
   nix flake check
   sudo nixos-rebuild switch --flake .#blessed
   ```

   After the first switch, log out and back in (or run `hyprctl reload`) so the new Hyprland session starts.

## Useful commands

| Command | What it does |
| --- | --- |
| `nix flake check` | Evaluate the flake without building |
| `nixos-rebuild build --flake .#blessed` | Build but do not activate |
| `sudo nixos-rebuild switch --flake .#blessed` | Build and activate now |
| `nix flake update` | Update `flake.lock` to latest inputs |
| `hyprctl reload` | Reload Hyprland config on the fly |

## Security / portability notes

- `hosts/blessed/default.nix` contains a **password hash** (`hashedPassword`) and **SDDM auto-login** settings. Review before making the repo public; use `sops-nix` or `agenix` if you want to keep it private.
- `hosts/blessed/hardware.nix` has **disk UUIDs** — it must be regenerated for other hardware.
- The wallpaper lives in `assets/wallpaper.jpg` and is installed to `~/.local/share/backgrounds/`.
- `home/modules/notifications.nix` is an old Mako config and is **not imported**; SwayNC handles notifications.

## Keybinds

- `Super + Q` — terminal (Kitty)
- `Super + R` — rofi launcher
- `Super + L` — lock screen (hyprlock)
- `Super + Shift + C` — SwayNC control center
- `Super + Shift + S` — screenshot area (swappy)
- `Super + 1..0` / `Ctrl + Alt + arrows` — workspaces
- `XF86Audio*` / `XF86MonBrightness*` — volume and brightness

## License

MIT — do whatever you want.
