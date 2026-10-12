# Shared system configuration — hardware-agnostic.
# Per-machine settings (hostname, hardware.nix, GPU drivers) go in
# hosts/<name>/default.nix which imports this file.
{ config, lib, pkgs, inputs, ... }:

let
  # Custom SDDM theme based on sddm-astronaut with our palette + wallpaper.
  sddm-astronaut = pkgs.sddm-astronaut;
  customSddmTheme = pkgs.stdenv.mkDerivation {
    name = "sddm-astronaut-custom";
    src = sddm-astronaut;
    dontBuild = true;

    installPhase = ''
      mkdir -p $out/share/sddm/themes/sddm-astronaut-theme/Backgrounds
      cp -rL $src/share/sddm/themes/sddm-astronaut-theme/* \
        $out/share/sddm/themes/sddm-astronaut-theme/
      chmod -R u+w $out
      cp ${./sddm-theme.conf} \
        $out/share/sddm/themes/sddm-astronaut-theme/theme.conf
      cp ${../assets/wallpaper.jpg} \
        $out/share/sddm/themes/sddm-astronaut-theme/Backgrounds/nixos.jpg
    '';
  };

  # Cisco Packet Tracer 8.2.2 — vendored derivation (nixpkgs dropped it).
  # Needs the .deb added to the store once per machine:
  #   nix-store --add-fixed sha256 PacketTracer822_amd64_signed_en-US_*.deb
  packetTracer8 = pkgs.callPackage ../pkgs/ciscoPacketTracer8/package.nix { };
in
{
  # ─── Boot ───────────────────────────────────────────────────────────
  # Requires UEFI. For legacy BIOS, override in hosts/<name>/default.nix.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = false;
    efi.efiSysMountPoint = "/boot";
  };

  # Boot splash between the loader menu and the session.
  # Theme names: ls /nix/store/*adi1090x-plymouth-themes*/share/plymouth/themes/
  boot.plymouth = {
    enable = true;
    theme = "dna";
    themePackages = [ pkgs.adi1090x-plymouth-themes ];
  };

  # External-monitor brightness via DDC/CI: the ddcci driver registers
  # each DDC-capable display as a /sys/class/backlight/ddcci* device, so
  # swaync's backlight slider and brightnessctl work on any monitor.
  boot.kernelModules = [ "i2c-dev" "ddcci" "ddcci_backlight" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];
  hardware.i2c.enable = true;

  # ─── Networking ─────────────────────────────────────────────────────
  networking.networkmanager.enable = true;

  # ─── Nix / Flakes ───────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  # PT8 bundles QtWebEngine 5.15 (known CVEs) — accepted consciously,
  # it is the version our course distributes.
  nixpkgs.config.permittedInsecurePackages = [ "ciscoPacketTracer8-8.2.2" ];

  # nix-daemon runs as root and never sees the session proxy env, so its
  # substituter/fetch traffic goes direct — and direct egress to
  # cache.nixos.org (Fastly) is unreachable from this ISP. Route it
  # through the local v2rayN instance instead; without this every fetch
  # stalls on connect timeouts and rebuilds take forever.
  # If v2rayN is not running, fetches fail either way — no regression.
  systemd.services.nix-daemon.environment = {
    http_proxy  = "http://127.0.0.1:10809";
    https_proxy = "http://127.0.0.1:10809";
    all_proxy   = "http://127.0.0.1:10809";
    no_proxy    = "localhost,127.0.0.1,::1";
  };

  # Same for the client side: `sudo nixos-rebuild` drops the session
  # env, so libgit2 fetches (flake inputs, `nix flake update`) would go
  # direct and stall. Keep proxy vars through sudo.
  security.sudo.extraConfig = ''
    Defaults env_keep += "http_proxy https_proxy all_proxy no_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY"
  '';

  # Weekly garbage collection — keeps the store bounded so old
  # generations and dead paths don't pile up.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # The installer-generated /etc/nixos/configuration.nix is a dead
  # template — a bare `nixos-rebuild switch` would silently build that
  # near-empty system and wipe the desktop setup. Replace it with a stub
  # that fails loudly and points at the real flake.
  environment.etc."nixos/configuration.nix".text = ''
    { ... }: {
      assertions = [{
        assertion = false;
        message = "This system is managed by the flake at ~/.dotfiles — use: nixos-rebuild --flake ~/.dotfiles#<host>";
      }];
    }
  '';

  services.xserver.enable = true;
  # Generic driver works on Intel/AMD/VMs. For NVIDIA override in the host:
  #   services.xserver.videoDrivers = [ "nvidia" ];
  #   hardware.nvidia.modesetting.enable = true;
  services.xserver.videoDrivers = lib.mkDefault [ "modesetting" ];
  hardware.graphics.enable = true;

  # ─── NVIDIA variant (boot-menu specialisation) ──────────────────────
  # Same config plus the proprietary driver, exposed as an extra
  # systemd-boot entry "NixOS - nvidia". The entry is safe on machines
  # WITHOUT NVIDIA hardware: the nvidia modules find no device, X falls
  # back to modesetting (it's second in videoDrivers) and the session
  # comes up normally. So the SSD can roam freely; picking the nvidia
  # entry once is enough everywhere.
  specialisation."nvidia" = {
    inheritParentConfig = true;
    configuration = {
      services.xserver.videoDrivers = [ "nvidia" "modesetting" ];
      hardware.nvidia = {
        modesetting.enable = true;
        # Turing (RTX 20xx) and newer are supported by the open modules.
        open = true;
        nvidiaSettings = false;
      };
      # Wayland greeter: no X server at login, so modesetting can't race
      # nvidia for the KMS device (the X-driver claim race killed SDDM).
      # On non-NVIDIA machines the greeter just uses i915/amdgpu instead.
      services.displayManager.sddm.wayland.enable = lib.mkForce true;
    };
  };

  # ─── Steam (also turns on 32-bit graphics libs for Proton/native games) ─
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  programs.gamemode.enable = true;

  hardware.enableAllFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.cpu.amd.updateMicrocode = true;

  # ─── Locale / Time ──────────────────────────────────────────────────
  time.timeZone = "Asia/Novosibirsk";
  i18n.defaultLocale = "en_US.UTF-8";
  # Russian names for dates etc. (waybar clock tooltip, calendars).
  i18n.extraLocales = [ "ru_RU.UTF-8/UTF-8" ];

  # ─── User ───────────────────────────────────────────────────────────
  users.users.blessed = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "i2c" ];
    shell = pkgs.zsh;
    hashedPassword = "$6$HvbFHwfqX5AmhLzQ$ZvH0EP4WPM9nkzxzmdrq7JCOyY1yphCsqlQBrwjEZnjCg4GGWArEJ4AIw8DMTH9T1/ePkEA8NboGC1x2t8sk9/";
  };

  # ─── Shells ─────────────────────────────────────────────────────────
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ bash zsh ];

  # ─── Audio (PipeWire) ───────────────────────────────────────────────
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    extraConfig.pipewire."10-flat-volumes" = {
      "context.properties" = {
        "flat-volumes" = false;
      };
    };
    extraConfig.pipewire-pulse."92-bt-default-volume" = {
      "pulse.properties" = {
        "server.address" = [ "unix:native" ];
      };
      "pulse.rules" = [
        {
          matches = [
            { "node.name" = "~bluez_output.*"; }
          ];
          actions = {
            update-props = {
              "session.suspend-timeout-seconds" = 0;
              "channelmix.normalize" = false;
              "resample.quality" = 15;
            };
          };
        }
      ];
    };

    # Per-device volume memory: WirePlumber stores routes (volume, mute,
    # channel volumes) per device in ~/.local/state/wireplumber and restores
    # them when the device reconnects — e.g. BT headphones keep their own
    # volume, independent from speakers. New devices otherwise start at ~6%.
    wireplumber.extraConfig."90-device-state" = {
      "wireplumber.settings" = {
        "device.restore-profile" = true;
        "device.restore-routes" = true;
        "node.restore-default-targets" = true;
        "bluetooth.use-persistent-storage" = true;
        "device.routes.default-sink-volume" = 0.4;
      };
    };
  };

  # UPower daemon — needed for Bluetooth headset battery levels
  # (waybar volume tooltip) and the laptop battery module.
  services.upower.enable = true;

  # ─── Bluetooth ──────────────────────────────────────────────────────
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Auto-connect trusted/paired devices (e.g. the realme Buds) when they
  # come in range, and power the adapter at boot.
  # AutoEnable powers the adapter at boot; trusted/paired devices
  # reconnect automatically via bluetoothd (there is no "AutoConnect"
  # main.conf key — the daemon ignores it and logs "Unknown key").
  hardware.bluetooth.settings = {
    Policy.AutoEnable = true;
    # Exposes org.bluez.Battery1 on devices that report charge (HFP
    # battery indicator / BLE Battery Service) — waybar's
    # {device_battery_percentage} reads exactly this.
    General.Experimental = true;
  };

  # The Realtek RTL8761 BT radio (0bda:a725) repeatedly tx-timeouts and
  # resets itself under USB autosuspend, which has been seen to wedge the
  # shared USB controller. Keep this specific device fully awake.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="a725", TEST=="power/control", ATTR{power/control}="on"

    # ddcci: attach the DDC/CI backlight driver to GPU i2c adapters so
    # external monitors appear in /sys/class/backlight (laptop panels
    # already have a native backlight device). Adapter names: nouveau
    # exposes "DP-N" / "NVIDIA * i2c adapter", i915 uses "*gmbus*",
    # amdgpu uses "*aux*".
    ACTION=="add", SUBSYSTEM=="i2c", ATTR{name}=="NVIDIA*", RUN+="${pkgs.bash}/bin/sh -c 'echo ddcci 0x37 > /sys/bus/i2c/devices/%k/new_device 2>/dev/null || true'"
    ACTION=="add", SUBSYSTEM=="i2c", ATTR{name}=="DP-*", RUN+="${pkgs.bash}/bin/sh -c 'echo ddcci 0x37 > /sys/bus/i2c/devices/%k/new_device 2>/dev/null || true'"
    ACTION=="add", SUBSYSTEM=="i2c", ATTR{name}=="*gmbus*", RUN+="${pkgs.bash}/bin/sh -c 'echo ddcci 0x37 > /sys/bus/i2c/devices/%k/new_device 2>/dev/null || true'"
    ACTION=="add", SUBSYSTEM=="i2c", ATTR{name}=="*aux*", RUN+="${pkgs.bash}/bin/sh -c 'echo ddcci 0x37 > /sys/bus/i2c/devices/%k/new_device 2>/dev/null || true'"

    # Let the video group write brightness so the SwayNC slider works
    # for an unprivileged session (blessed is in "video").
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.bash}/bin/sh -c 'chgrp video /sys/class/backlight/%k/brightness && chmod g+w /sys/class/backlight/%k/brightness'"
  '';

  # ─── Memory pressure / freeze resilience ────────────────────────────
  # No disk swap on this box. A hard freeze with an abruptly-truncated
  # journal is the signature of an OOM live-lock: every CPU stuck in
  # direct reclaim, journald never scheduled. zram gives cheap
  # compressed swap (~2-3x effective); earlyoom kills the memory hog
  # before the system wedges completely.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
  };

  # Breadcrumb for the next hang: log kernel tasks blocked >120s so the
  # journal captures *something* instead of cutting off silently.
  boot.kernel.sysctl."kernel.hung_task_timeout_secs" = 120;

  # ─── Ollama (local embeddings backend for Gnostis MCP) ──────────────
  # Exposes OpenAI-compatible /v1/embeddings on http://localhost:11434/v1
  services.ollama = {
    enable = true;
    loadModels = [ "nomic-embed-text" ];
  };

  # ─── Polkit (auth agent for GUI privilege escalation) ───────────────
  security.polkit.enable = true;
  security.pam.services.hyprlock = {};

  # ─── Secret Service (API-ключи coucou и др. живут в keyring) ─────────
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  # ─── Nix-LD (run prebuilt binaries like TgWsProxy / PyInstaller apps) ─
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    openssl
    zlib
    # X11 / tkinter GUI support (customtkinter apps)
    libx11
    libxcb
    libxau
    libxdmcp
    libxext
    libxrender
    libxi
    libxcursor
    libxcomposite
    libxdamage
    libxfixes
    libxrandr
    libxinerama
    libxtst
    libxscrnsaver
    fontconfig
    freetype
    glib
    # GTK3 tray support (pystray / appindicator)
    gtk3
    wayland
    pango
    cairo
    gdk-pixbuf
    libayatana-appindicator
    dbus
    # Electron / Chromium deps
    nss
    nspr
    atk
    at-spi2-atk
    cups
    libdrm
    mesa
    libgbm
    libxkbcommon
    expat
    alsa-lib
    libpulseaudio
    # Discord / Electron GL
    libGL
    libglvnd
    vulkan-loader
  ];

  # ─── Hyprland ───────────────────────────────────────────────────────
  programs.hyprland = {
    enable = true;
    withUWSM = false;
    xwayland.enable = true;
  };

  programs.firefox.enable = true;

  # ─── Display Manager (SDDM) ─────────────────────────────────────────
  # Graphical login screen — replaces TTY login.
  # CRITICAL: defaultSession forces the plain Hyprland session. Without
  # it SDDM picks hyprland-uwsm.desktop (shipped by the hyprland package),
  # which crashes immediately without uwsm integration (this broke gen 14).
  services.displayManager.defaultSession = "hyprland";

  # Boot straight into Hyprland without a password (hyprlock protects
  # the session). The SDDM greeter still appears on logout.
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
    theme = "sddm-astronaut-theme";
    settings.Autologin = {
      User = "blessed";
      Session = "hyprland";
      Relogin = true;
    };
  };

  # ─── XDG Desktop Portal ─────────────────────────────────────────────
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # ─── Fonts ──────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    inter
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];
  fonts.fontconfig.defaultFonts = {
    monospace = [ "JetBrainsMono Nerd Font" "Noto Sans Mono CJK SC" ];
    sansSerif = [ "Noto Sans CJK SC" ];
    emoji = [ "Noto Color Emoji" ];
  };

  # ─── Session environment ────────────────────────────────────────────
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_SIZE = "24";
  };

  # ─── System packages ────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # core
    git vim wget nano unzip
    python3
    linphone
    baresip
    sqlite
    proxychains-ng
    redsocks
    kitty
    # wayland / hyprland tooling
    waybar rofi hyprpaper hyprlock hypridle mako
    grim slurp swappy wl-clipboard hyprpicker
    brightnessctl playerctl libnotify
    # portal / polkit agent
    polkit_gnome xdg-desktop-portal-gtk
    # network / bluetooth
    networkmanagerapplet blueman
    # file manager
    kdePackages.dolphin
    # dev (editors managed via home-manager)
    opencode
    # Cisco Packet Tracer 8.2.2 — see packetTracer8 let-binding above
    packetTracer8
    # SDDM custom theme (provides sddm-astronaut-theme with our colors + wallpaper)
    customSddmTheme
  ];

  system.stateVersion = "26.05";
}
