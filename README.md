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
├── flake.nix                 # entry point — one target per machine
├── flake.lock                # pinned inputs
├── hosts/
│   ├── common.nix            # shared, hardware-agnostic system config
│   ├── sddm-theme.conf       # SDDM theme overrides
│   ├── blessed/
│   │   ├── default.nix       # hostname + hardware.nix import
│   │   └── hardware.nix      # disk UUIDs / initrd — laptop specific
│   └── desktop/
│       ├── default.nix       # hostname + hardware.nix import
│       └── hardware.nix      # stub — replace with nixos-generate-config output
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

2. On a **new machine** pick a host name, e.g. `desktop`, and generate its
   `hardware.nix` (disk UUIDs, initrd modules, CPU microcode):

   ```bash
   sudo nixos-generate-config --root /mnt --show-hardware-config > hosts/desktop/hardware.nix
   ```

   `hosts/desktop/default.nix` already imports `../common.nix` and sets
   `networking.hostName = "desktop"`. For NVIDIA add the lines commented
   out in that file.

   For another machine name, copy `hosts/desktop` to `hosts/<name>` and add
   `nixosConfigurations.<name> = mkHost "<name>";` in `flake.nix`.

3. Build and activate:

   ```bash
   nix flake check
   sudo nixos-rebuild switch --flake .#desktop
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

- `hosts/common.nix` contains a **password hash** (`hashedPassword`) and **SDDM auto-login** settings. Review before making the repo public; use `sops-nix` or `agenix` if you want to keep it private.
- `hosts/<name>/hardware.nix` has **disk UUIDs** — it must be generated per machine.
- The wallpaper lives in `assets/wallpaper.jpg` and is installed to `~/.local/share/backgrounds/`.
- `home/modules/notifications.nix` is an old Mako config and is **not imported**; SwayNC handles notifications.

## Keybinds

- `Super + Q` — terminal (Kitty)
- `Super + R` — rofi launcher
- `Super + L` — lock screen (hyprlock)
- `Super + N` / `Super + Shift + C` — SwayNC notification overlay / control center
- `Super + Shift + V` — clipboard history (cliphist)
- `Super + .` — emoji picker (rofimoji)
- `Super + Ctrl + W` — wallpaper picker (rofi)
- `Super + Shift + S` — screenshot area (swappy)
- `Super + 1..0` / `Ctrl + Alt + arrows` — workspaces
- `XF86Audio*` / `XF86MonBrightness*` — volume and brightness (SwayOSD)

## License

MIT — do whatever you want.
