# Portable NixOS — boots the same SSD on different machines.
# hardware.nix imports the broad "not-detected" initrd set and only
# needs this SSD's fileSystems (same UUIDs on every machine).
{ ... }:
{
  imports = [
    ../common.nix
    ./hardware.nix
  ];

  networking.hostName = "nixos";

  # Per-machine GPU override if needed:
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia.modesetting.enable = true;
}
