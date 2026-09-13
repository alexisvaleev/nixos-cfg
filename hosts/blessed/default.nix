# blessed's laptop (nixos). Hardware-specific settings live in
# hardware.nix; shared settings live in ../common.nix.
{ ... }:
{
  imports = [
    ../common.nix
    ./hardware.nix
  ];

  networking.hostName = "nixos";
}
