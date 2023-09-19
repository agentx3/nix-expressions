{ lib }:

let
  inherit (lib) mkOption types;
in
{
  x3NetworkType = types.submodule ({ ... }: {
    options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Whether to enable this. This is supposed to be the docker network for nix-configured docker services on the x3framework";
      };
      name = mkOption {
        type = types.str;
        default = "x3framework-net";
        description = lib.mdDoc ''Name for the docker network'';
      };
      subnetBase = mkOption {
        type = types.str;
        default = "172.30.0.0";
        description = lib.mdDoc "Subnet IP range";
      };
      subnetMaskLength = mkOption {
        type = types.str;
        default = "24";
        description = lib.mdDoc "Mask for the subnet";
      };
    };
  });
}
