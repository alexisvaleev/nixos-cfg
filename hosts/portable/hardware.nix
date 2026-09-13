# Hardware configuration for a portable SSD.
# imports not-detected.nix → broad boot.initrd.availableKernelModules,
# so the system finds SATA/NVMe/USB/Net on almost any machine.
#
# Fill in fileSystems/swapDevices from ONE machine while the SSD is in it:
#   nixos-generate-config --show-hardware-config | grep -A5 fileSystems
# The UUIDs stay the same regardless of which machine the SSD is in.
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # FIXME: replace with the SSD's real layout (get from nixos-generate-config).
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  # fileSystems."/boot" = { device = "/dev/disk/by-label/boot"; fsType = "vfat"; };
  # swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

  # CPU microcode for both vendors — safe to enable on any machine.
  hardware.cpu.intel.updateMicrocode = true;
  hardware.cpu.amd.updateMicrocode = true;
}
