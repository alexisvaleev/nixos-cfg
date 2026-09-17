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
in
{
  # ─── Boot ───────────────────────────────────────────────────────────
  # Requires UEFI. For legacy BIOS, override in hosts/<name>/default.nix.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = false;
    efi.efiSysMountPoint = "/boot";
  };

  # ─── Networking ─────────────────────────────────────────────────────
  networking.networkmanager.enable = true;

  # ─── Nix / Flakes ───────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  services.xserver.enable = true;
  # Generic driver works on Intel/AMD/VMs. For NVIDIA override in the host:
  #   services.xserver.videoDrivers = [ "nvidia" ];
  #   hardware.nvidia.modesetting.enable = true;
  services.xserver.videoDrivers = lib.mkDefault [ "modesetting" ];
  hardware.graphics.enable = true;
  hardware.enableAllFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.cpu.amd.updateMicrocode = true;

  # ─── Locale / Time ──────────────────────────────────────────────────
  time.timeZone = "Asia/Novosibirsk";
  i18n.defaultLocale = "en_US.UTF-8";

  # ─── User ───────────────────────────────────────────────────────────
  users.users.blessed = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
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

  # ─── Bluetooth ──────────────────────────────────────────────────────
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Auto-connect trusted/paired devices (e.g. the realme Buds) when they
  # come in range, and power the adapter at boot.
  hardware.bluetooth.settings = {
    General.AutoEnable = true;
    Policy.AutoConnect = true;
  };

  # The Realtek RTL8761 BT radio (0bda:a725) repeatedly tx-timeouts and
  # resets itself under USB autosuspend, which has been seen to wedge the
  # shared USB controller. Keep this specific device fully awake.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="a725", TEST=="power/control", ATTR{power/control}="on"
  '';

  # ─── Ollama (local embeddings backend for Gnostis MCP) ──────────────
  # Exposes OpenAI-compatible /v1/embeddings on http://localhost:11434/v1
  services.ollama = {
    enable = true;
    loadModels = [ "nomic-embed-text" ];
  };

  # ─── Polkit (auth agent for GUI privilege escalation) ───────────────
  security.polkit.enable = true;
  security.pam.services.hyprlock = {};

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
    # SDDM custom theme (provides sddm-astronaut-theme with our colors + wallpaper)
    customSddmTheme
  ];

  system.stateVersion = "26.05";
}
