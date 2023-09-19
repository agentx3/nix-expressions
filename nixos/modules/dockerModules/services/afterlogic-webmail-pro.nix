{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf strings;

  docker = "${ config.virtualisation.docker.package }/bin/docker";
  service = "afterlogic-webmail-pro";
  IP4 = "93";
  mkIp = config.lib.x3framework.mkIPFromSubnetAndSuffix;
  SERVICE_IP = mkIp cfg.network.subnetBase IP4;
  cfg = config.x3framework.docker.services.afterLogicWebmail;

  composeFile = pkgs.writeTextFile {
    name = "${service}-compose.yml";
    text = builtins.toJSON {
      version = "3.2";
      services = {
        ${service} = {
          container_name = service;
          image = cfg.image;
          ports = [
            (toString cfg.dockerPort)
          ];
          depends_on = [ "db" ];
          environment = cfg.environment;
          env_file = cfg.env_file;
          restart = cfg.restart;
          networks.${cfg.network.name}.ipv4_address = SERVICE_IP;
          volumes = [ "${service}-web-data:/var/www/html/data" ];
        };
        db = {
          image = "mysql:8";
          command = " --default-authentication-plugin=mysql_native_password";
          volumes = [ "${service}-mysql-data:/var/lib/mysql" ];
          env_file = cfg.env_file;
          cap_add = [ "SYS_NICE" ];
          networks.${cfg.network.name} = { };
        };
      };
      networks."${cfg.network.name}".external = true;
      volumes = {
        "${service}-mysql-data" = { };
        "${service}-web-data" = { };
      };
    };
  };
in
{
  options.x3framework.docker.services.afterLogicWebmail = with lib ;{
    enable = mkEnableOption "" // {
      description = ''
        Whether to enable the container task. Enable this if the configuration
        is deployed to a NixOS container.
      '';
    };
    enableSystemd = mkOption {
      type = types.bool;
      description = mdDoc "Enable a systemd service that will automatically start and stop as necessary in conjunction with the network";
      default = true;
    };
    image = mkOption {
      type = types.str;
      description = mdDoc "Image for the container";
      default = "afterlogic/docker-webmail-lite:latest";
    };
    restart = mkOption {
      type = types.str;
      description = mdDoc "Restart directive for the container";
      default = "unless-stopped";
    };
    dockerPort = mkOption {
      type = types.int;
      default = 80;
      description = mdDoc "Port for the docker container";
    };
    containerIp = mkOption {
      type = types.str;
      default = SERVICE_IP;
      description = mdDoc "IP address for the docker container";
    };
    environment = mkOption {
      type = types.attrs;
      description = mdDoc "Environment variables for the docker container.";
      default = { };
    };
    env_file = mkOption {
      type = types.str;
      default = ''""'';
      description = mdDoc "Environment file for the docker container.";
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
        message = "The framework's dockerNetwork must be enabled to use this";
      }
    ];
    x3framework.helper.${service}.composeFile = composeFile;

    # Define docker-compose.yml and Dockerfile
    systemd.services."${service}-x3framework" = mkIf cfg.enableSystemd (
      import ./mkSystemdUnit.nix { inherit config docker service composeFile; network = cfg.network; }
    );
  };
}

