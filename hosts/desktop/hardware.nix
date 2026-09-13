# Hardware configuration for this machine.
# REPLACE THIS FILE with the output of:
#   nixos-generate-config --show-hardware-config > hosts/desktop/hardware.nix
# or copy the generated /etc/nixos/hardware-configuration.nix here.
# The stub below only exists so `nix flake check` can evaluate the host.
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # FIXME: replace with real disk/filesystem layout from nixos-generate-config.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  # boot.kernelModules = [ "kvm-intel" ];  # or "kvm-amd"
  # swapDevices = [ ];
}
