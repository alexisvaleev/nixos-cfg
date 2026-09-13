# blessed's desktop. Hardware-specific settings live in hardware.nix
# (generate with: nixos-generate-config --show-hardware-config > hardware.nix).
{ ... }:
{
  imports = [
    ../common.nix
    ./hardware.nix
  ];

  networking.hostName = "desktop";

  # Uncomment for NVIDIA:
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia.modesetting.enable = true;
  # hardware.nvidia.open = false;  # or true for open kernel modules
}
