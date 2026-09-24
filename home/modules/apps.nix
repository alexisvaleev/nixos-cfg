# User applications: Telegram, VSCode, Zed, v2rayN (+ proxy cores), Fastfetch, rofi menus.
# v2rayN cores are symlinked into its data directory via an activation script,
# because v2rayN can't download them itself (chicken-and-egg: no internet without proxy).
{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    # messaging / browsers
    telegram-desktop
    # Vesktop: Discord client with working Wayland screen share
    # (portal + pipewire). Stock Discord can't share on Hyprland.
    vesktop
    # editors
    vscode-fhs
    zed-editor
    # proxy
    v2rayn
    xray
    sing-box
    mihomo
    # geo data for xray routing — v2ray-rules-dat (Loyalsoldier) is REQUIRED:
    # it contains service categories in UPPER case (FACEBOOK, GOOGLE, TELEGRAM,
    # NETFLIX, FASTLY, PRIVATE) that routing rules like "geoip:facebook" expect.
    # The official v2fly v2ray-geoip only has country codes and breaks the core.
    v2ray-rules-dat
    # system info
    fastfetch
    # rofi-based menus for network & bluetooth (clickable from waybar)
    networkmanager_dmenu
    rofi-bluetooth
  ];

  # Vesktop through the local v2rayN proxy (Discord is unreachable
  # without it — same proxy env as the stock-Discord wrapper).
  home.file.".local/bin/vesktop" = {
    executable = true;
    text = ''
      #!/usr/bin/env sh
      export http_proxy="http://127.0.0.1:10809"
      export https_proxy="http://127.0.0.1:10809"
      export ALL_PROXY="http://127.0.0.1:10809"
      # Devin/VS Code terminals leak ELECTRON_RUN_AS_NODE=1, which makes
      # Electron run as plain node -> "Cannot find module 'electron'".
      unset ELECTRON_RUN_AS_NODE ELECTRON_NO_ATTACH_CONSOLE
      exec ${pkgs.vesktop}/bin/vesktop "$@"
    '';
  };

  # The package's own .desktop lands in the system profile only after
  # nixos-rebuild, and it would launch vesktop without the proxy anyway.
  # This entry goes through the wrapper above so Discord traffic uses v2rayN.
  home.file.".local/share/applications/vesktop.desktop" = {
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Vesktop
      Comment=Discord client (via v2rayN proxy)
      Exec=${config.home.homeDirectory}/.local/bin/vesktop %U
      Icon=${pkgs.vesktop}/share/icons/hicolor/256x256/apps/vesktop.png
      Categories=Network;InstantMessaging;Chat;
      StartupWMClass=vesktop
      MimeType=x-scheme-handler/discord;
    '';
  };

  # ─── Link proxy cores + geo data into v2rayN's bin directory ───────
  # v2rayN expects cores in ~/.local/share/v2rayN/bin/<name>/<binary>.
  # Xray loads geo data from its working directory (bin/ root), so the
  # dat files are symlinked there (and into bin/xray/ for completeness).
  # This runs after every home-manager activation so it stays in sync.
  home.activation.linkV2rayCores = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    v2ray_bin="$HOME/.local/share/v2rayN/bin"
    $DRY_RUN_CMD mkdir -p "$v2ray_bin/xray" "$v2ray_bin/sing_box" "$v2ray_bin/mihomo"

    # core binaries
    $DRY_RUN_CMD ln -sf ${pkgs.xray}/bin/xray         "$v2ray_bin/xray/xray"
    $DRY_RUN_CMD ln -sf ${pkgs.sing-box}/bin/sing-box  "$v2ray_bin/sing_box/sing-box"
    $DRY_RUN_CMD ln -sf ${pkgs.mihomo}/bin/mihomo      "$v2ray_bin/mihomo/mihomo"

    # geo data — v2ray-rules-dat (has FACEBOOK/GOOGLE/TELEGRAM/... categories)
    # in bin/ root: this is xray's working directory when launched by v2rayN
    $DRY_RUN_CMD ln -sf ${pkgs.v2ray-rules-dat}/share/v2ray/geoip.dat   "$v2ray_bin/geoip.dat"
    $DRY_RUN_CMD ln -sf ${pkgs.v2ray-rules-dat}/share/v2ray/geosite.dat "$v2ray_bin/geosite.dat"
    $DRY_RUN_CMD rm -f "$v2ray_bin/geoip-only-cn-private.dat"

    # same files in bin/xray/ (xray's own subdir, for direct core runs)
    $DRY_RUN_CMD ln -sf ${pkgs.v2ray-rules-dat}/share/v2ray/geoip.dat   "$v2ray_bin/xray/geoip.dat"
    $DRY_RUN_CMD ln -sf ${pkgs.v2ray-rules-dat}/share/v2ray/geosite.dat "$v2ray_bin/xray/geosite.dat"
    $DRY_RUN_CMD rm -f "$v2ray_bin/xray/geoip-only-cn-private.dat"
  '';
}
