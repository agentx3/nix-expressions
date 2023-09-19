{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf strings mkDefault;

  docker = "${ config.virtualisation.docker.package }/bin/docker";
  service = "changedetection";
  IP4 = "33";
  mkIp = config.lib.x3framework.mkIPFromSubnetAndSuffix;
  SERVICE_IP = mkIp cfg.network.subnetBase IP4;
  x3cfg = config.x3framework;
  cfg = config.x3framework.docker.changeDetection;

  localFirewallCommands = cf: x: /* bash */ ''
    # changedetection
    iptables ${x} INPUT -p udp --dport ${toString cf.hostPort} -s ${cf.LANSubnet} -j ACCEPT
    iptables ${x} INPUT -p tcp --dport ${toString cf.hostPort} -s ${cf.LANSubnet} -j ACCEPT

    # Deny all other DNS requests
    iptables ${x} INPUT -p udp --dport ${toString cf.hostPort} -j DROP
    iptables ${x} INPUT -p tcp --dport ${toString cf.hostPort} -j DROP
  '';
  extraFirewallCommands = c: (localFirewallCommands c "-A");
  cleanupFirewallCommands = c: (localFirewallCommands c "-D");
  firewallCommands = cf: { extraCommands = extraFirewallCommands cf; extraStopCommands = cleanupFirewallCommands cf; };

  playwrightType = lib.types.submodule ({ ... }: with lib.types; {
    options = with lib;{
      enable = mkOption {
        type = bool;
        default = false;
        description = lib.mdDoc ''
          Whether to enable the playwright container
        '';
      };
      image = mkOption {
        type = str;
        default = "browserless/chrome";
        description = lib.mdDoc ''
          Image for the playwright container
        '';
      };
      environment = mkOption {
        type = attrs;
        description = lib.mdDoc ''
          Image for the playwright container
        '';
        default = {
          SCREEN_WIDTH = 1920;
          SCREEN_HEIGHT = 1024;
          SCREEN_DEPTH = 16;
          ENABLE_DEBUGGER = false;
          PREBOOT_CHROME = true;
          CONNECTION_TIMEOUT = 300000;
          MAX_CONCURRENT_SESSIONS = 10;
          CHROME_REFRESH_TIME = 600000;
          DEFAULT_BLOCK_ADS = true;
          DEFAULT_STEALTH = true;
        };
      };

    };
  });

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
          environment = cfg.environment // (if cfg.playwright.enable then {
            PLAYWRIGHT_DRIVER_URL = "ws://playwright-chrome:3000/?stealth=1&--disable-web-security=true";
          } else { });
          depends_on =
            if cfg.playwright.enable then {
              playwright-chrome.condition = "service_started";
            } else { };
          volumes = [
            "${service}-data:/datastore"
          ] ++ lib.optionals (cfg.extraProxiesJson != null) [
            "${cfg.extraProxiesJson}:/datastore/proxies.json"

          ];
          restart = cfg.restart;
          networks.${cfg.network.name}.ipv4_address = SERVICE_IP;
        };
        playwright-chrome =
          if cfg.playwright.enable then {
            hostname = "playwright-chrome";
            image = cfg.playwright.image;
            restart = cfg.restart;
            networks.${cfg.network.name} = { };
            environment = cfg.playwright.environment;
          } else { };
      };
      volumes = {
        "${service}-data" = { };
      };
      networks."${cfg.network.name}".external = true;
    };
  };
in
{
  options.x3framework.docker.changeDetection = with lib ;{
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
    host = mkOption {
      type = types.str;
      description = mdDoc "Host address of system";
      example = "192.168.0.10";
    };
    LANSubnet = mkOption {
      type = types.nullOr types.str;
      default = "192.168.0.0/24";
      description = mdDoc "Subnet of the local network, to be used to restrict local access to the web interface only.";
    };
    image = mkOption {
      type = types.str;
      description = mdDoc "Image for the container";
      default = "ghcr.io/dgtlmoon/changedetection.io";
    };
    playwright = mkOption {
      type = types.nullOr playwrightType;
      description = mdDoc "Settings for the playwright container";
    };
    restart = mkOption {
      type = types.str;
      description = mdDoc "Restart directive for the container";
      default = "unless-stopped";
    };
    hostPort = mkOption {
      type = types.int;
      default = 5001;
      description = mdDoc "Port for nginx to listen to forward to the web interface";
    };
    dockerPort = mkOption {
      type = types.int;
      default = 80;
      description = mdDoc "Port for the docker container";
    };
    enableFirewall = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc "Add extra rules to the firewall to restrict access from external IPs";
    };
    enableNginxServer = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc "Create a nginx server to forward host port to container";
    };
    extraProxiesJson = mkOption {
      type = types.nullOr types.path;
      description = mdDoc "A path to a json list of proxies. See https://github.com/dgtlmoon/changedetection.io/wiki/Proxy-configuration#proxy-list-support .";
      default = null;
    };
    environment = mkOption {
      type = types.attrs;
      description = mdDoc "Environment variables for the docker container.";
      default = {
        PUID = 1000;
        PGID = 1000;
        PORT = toString cfg.dockerPort;
        BASE_URL = "http://${cfg.host}:${toString cfg.hostPort}";

      };
      network = mkOption {
        type = config.lib.x3framework.types.x3NetworkType;
        default = config.x3framework.docker.networks.default;
        description = mdDoc "The docker network to use for the container";
      };
    };


  };
  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = x3cfg.dockerNetwork.enable;
        message = "The framework's dockerNetwork must be enabled to use this";
      }
      (mkIf cfg.enableNginxServer {
        assertion = config.services.nginx.enable;
        message = "The nginx must be enabled to use this";
      }
      )
    ];

    networking.firewall = mkIf cfg.enableFirewall (firewallCommands cfg);

    x3framework.helper.${service}.composeFile = composeFile;

    services.nginx.virtualHosts = mkIf cfg.enableNginxServer {
      changeDetectionLAN = {
        listen = [
          {
            addr = cfg.host;
            port = cfg.hostPort;
            ssl = false;
          }
        ];
        http2 = true;
        serverName = cfg.host;
        locations = {
          "/" = {
            extraConfig = /*nginx*/''
              allow ${cfg.LANSubnet};
              deny all;
              proxy_pass               http://${SERVICE_IP}:${toString cfg.dockerPort};
              proxy_http_version       1.1;
              proxy_set_header         Upgrade $http_upgrade;
              proxy_set_header         Connection "Upgrade";
              proxy_set_header         Host $host;
              proxy_set_header         X-Real-IP $remote_addr;
              proxy_set_header         X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header         X-Forwarded-Proto $scheme;
              proxy_set_header         X-Forwarded-Host $host;
              proxy_set_header         X-Forwarded-Server $host;
              proxy_set_header         X-Forwarded-Port $server_port;
            '';

          };
        };
      };
    };
    # Define docker-compose.yml and Dockerfile
    systemd.services."${service}-x3framework" = mkIf cfg.enableSystemd (
      import ./mkSystemdUnit.nix { inherit config docker service composeFile; network = cfg.network; }
    );
  };
}

