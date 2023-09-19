{ config, lib, ... }:

let
  inherit (lib) mkDefault types mkOption nameValuePair mapAttrs';
  cfg = config.x3framework.docker.networks;
  x3networks = mapAttrs'
    (n: v: nameValuePair
      (v.name)
      ({ enable = v.enable; subnet = [ "${v.subnetBase}/${v.subnetMaskLength}" ]; })
    )
    cfg;
in
{
  options.x3framework.docker.networks = mkOption {
    default = { };
    type = types.attrsOf config.lib.x3framework.types.x3NetworkType;
    example = {
      "main" = {
        enable = true;
        name = "x3framework-net";
        subnetBase = "172.30.0.0";
        subnetMaskLength = "24";
      };
    };
    description = lib.mdDoc ''
      An attribute set of docker networks and their configurations. See https://docs.docker.com/engine/reference/commandline/network_create/ for more info on the options.
    '';
  };

  config = {
    virtualisation.docker.networks = x3networks;
    # virtualisation.docker.networks = {
    #   ${cfg.name} = {
    #     subnet = [ "${cfg.subnetBase}/${cfg.subnetMaskLength}" ];
    #   };
    # };


  };
}
