{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkOption mkIf types mdDoc;
  service = "kanboard";
  IP4 = "5";
  cfg = config.x3framework.docker.services.kanboard;
  mkIp = config.lib.x3framework.mkIPFromSubnetAndSuffix;
  SERVICE_IP = mkIp cfg.network.subnetBase IP4;
  # DATA_DIR = "/data/${SERVICE}";
  composeFile = pkgs.writeTextFile {
    name = "${service}-compose.yml";
    text = builtins.toJSON {
      version = "3.9";
      services = {
        kanboard = {
          restart = "unless-stopped";
          container_name = "${service}";
          image = cfg.image;
          environment = cfg.environment;
          networks."${cfg.network.name}".ipv4_address = SERVICE_IP;
          volumes = [
            "${service}_data:/var/www/app/data"
            "${service}_plugins:/var/www/app/plugins"
            "${service}_ssl:/etc/nginx/ssl"
          ];
        } // (if (cfg.envFile != null) then { env_file = cfg.envFile; } else { });
      };
      volumes = {
        "${service}_data" = { };
        "${service}_plugins" = { };
        "${service}_ssl" = { };
      };
      networks."${cfg.network.name}".external = true;
    };
  };
in
{
  options.x3framework.docker.services."${service}" = {
    enable = mkEnableOption "" // {
      description = ''
        Whether to enable the container task. Enable this if the configuration
        is deployed to a NixOS container.
      '';
    };
    containerIp = mkOption {
      type = types.str;
      default = SERVICE_IP;
      description = mdDoc "IP address of the container. Needs to be in subnet of the assigned network";
    };
    image = mkOption {
      type = types.str;
      description = mdDoc "Image to use for the container";
      default = "kanboard/kanboard";
    };
    envFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = mdDoc "Path to an environment file for the docker container.";
    };
    environment = mkOption {
      type = types.attrs;
      default = { };
      description = mdDoc "Additional environment variables to pass to the container";
    };
    network = mkOption {
      type = config.lib.x3framework.types.x3NetworkType;
      default = config.x3framework.docker.networks.default;
      description = mdDoc "The docker network to use for the container";
    };
  };
  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.network.enable;
        message = "The framework's docker network must be enabled to use this";
      }
    ];

    x3framework.helper.${service}.composeFile = composeFile;

    systemd.services."${service}-x3framework" = config.lib.x3framework.mkSystemdUnit { inherit config service composeFile; network = cfg.network; };

  };
}

