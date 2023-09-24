{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkOption mkIf types mdDoc;
  service = "roundcube";
  IP4 = "101";
  cfg = config.x3framework.docker.services.roundcube;
  mkIp = config.lib.x3framework.mkIPFromSubnetAndSuffix;
  SERVICE_IP = mkIp cfg.network.subnetBase IP4;
  # DATA_DIR = "/data/${SERVICE}";
  mkExtraConfig = extraConfig: pkgs.writeTextFile {
    name = "${service}-extra-config.inc.php";
    text = extraConfig;
  };
  composeFile = pkgs.writeTextFile {
    name = "${service}-compose.yml";
    text = builtins.toJSON {
      version = "3.9";
      services = {
        roundcube = {
          restart = "unless-stopped";
          container_name = "${service}";
          image = cfg.image;
          environment = {
            # See https://github.com/roundcube/roundcubemail-docker/blob/master/README.md
            # for explanations of the environment variables
            ROUNDCUBEMAIL_DEFAULT_HOST = cfg.host;
            ROUNDCUBEMAIL_DEFAULT_PORT = toString cfg.port;
            ROUNDCUBEMAIL_SMTP_SERVER = cfg.smtpServer;
            ROUNDCUBEMAIL_SMTP_PORT = toString cfg.smtpPort;
          } // cfg.environment;
          networks."${cfg.network.name}".ipv4_address = SERVICE_IP;
          volumes = [
            "${service}-db:/var/roundcube/db"
            "${service}-config:/var/roundcube/config"
            "${service}-temp:/tmp/roundcube-temp"
            "${service}-html:/var/www/html"
          ] ++ lib.optionals (cfg.extraConfig != "") [
            "${mkExtraConfig cfg.extraConfig}:/var/roundcube/config/extra-config.inc.php"
          ] ++ lib.optionals (cfg.extraOauthConfigFile != "") [
            "${cfg.extraOauthConfigFile}:/var/roundcube/config/extra-oauth.inc.php"
          ];
        };
      };
      volumes = {
        "${service}-db" = { };
        "${service}-config" = { };
        "${service}-temp" = { };
        "${service}-html" = { };
      };
      networks."${cfg.network.name}".external = true;
    };
  };
in
{
  options.x3framework.docker.services.roundcube = {
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
    smtpServer = mkOption {
      type = types.str;
      description = mdDoc "Location of the smtp server";
    };
    host = mkOption {
      type = types.str;
      description = mdDoc "Location of the host mail server";
    };
    port = mkOption {
      type = types.int;
      default = 143;
      description = mdDoc "Port to use for IMAP. Usually 993 for forced TLS, 143 for STARTTLS";
    };
    smtpPort = mkOption {
      type = types.int;
      default = 587;
      description = mdDoc "Port to use for SMTP. Usually 465 for forced TLS, 587 for STARTTLS";
    };
    image = mkOption {
      type = types.str;
      description = mdDoc "Image to use for the container";
      default = "roundcube/roundcubemail";
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
    extraConfig = mkOption {
      type = types.str;
      default = "";
      description = mdDoc "Additional configuration to pass to the roundcube php config file";
    };
    extraOauthConfigFile = mkOption {
      type = types.oneOf [ types.path types.str ];
      default = "";
      description = mdDoc "Additional configuration file to pass to the roundcube oauth config file";
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

