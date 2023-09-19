{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf strings;

  docker = "${ config.virtualisation.docker.package }/bin/docker";
  service = "pi-hole";
  IP4 = "252";
  cfg = config.x3framework.docker.services.pi-hole;
  mkIp = config.lib.x3framework.mkIPFromSubnetAndSuffix;
  SERVICE_IP = mkIp cfg.network.subnetBase IP4;

  localFirewallCommands = cf: X: /* bash */ ''
    # Only allow local IPs to access the DNS and its upstream
    # pihole
    iptables ${X} INPUT -p udp --dport 53 -s ${cf.LANSubnet} -j ACCEPT
    iptables ${X} INPUT -p tcp --dport 53 -s ${cf.LANSubnet} -j ACCEPT
    iptables ${X} INPUT -p udp --dport 53 -s ${cfg.network.subnetBase}/${cfg.network.subnetMaskLength} -j ACCEPT
    iptables ${X} INPUT -p tcp --dport 53 -s ${cfg.network.subnetBase}/${cfg.network.subnetMaskLength} -j ACCEPT
    # pihole interface
    iptables ${X} INPUT -p udp -s ${cf.LANSubnet} --dport ${toString cf.hostPort} -j ACCEPT
    iptables ${X} INPUT -p tcp -s ${cf.LANSubnet} --dport ${toString cf.hostPort} -j ACCEPT

    # Deny all other DNS requests
    iptables ${X} INPUT -p udp --dport 53 -j DROP
    iptables ${X} INPUT -p tcp --dport 53 -j DROP
    iptables ${X} INPUT -p udp --dport ${toString cf.hostPort} -j DROP
    iptables ${X} INPUT -p tcp --dport ${toString cf.hostPort} -j DROP
  '';
  dockerFirewallCommands = cf: X: /* bash */ ''
    # This is to prevent external access of the DNS
    iptables ${X} DOCKER-USER -p udp --dport 53 -j DROP
    iptables ${X} DOCKER-USER -p tcp --dport 53 -j DROP
    iptables ${X} DOCKER-USER -p udp --dport 53 -s ${cf.LANSubnet} -j ACCEPT
    iptables ${X} DOCKER-USER -p tcp --dport 53 -s ${cf.LANSubnet} -j ACCEPT
  '';
  extraFirewallCommands = c: (localFirewallCommands c "-A") + (dockerFirewallCommands c "-I");
  cleanupFirewallCommands = c: (localFirewallCommands c "-D") + (dockerFirewallCommands c "-D");
  firewallCommands = cf: { extraCommands = extraFirewallCommands cf; extraStopCommands = cleanupFirewallCommands cf; };

  composeFile = pkgs.writeTextFile {
    name = "${service}-compose.yml";
    text = builtins.toJSON {
      version = "3";
      services = {
        ${service} = {
          container_name = service;
          image = cfg.image;
          ports = [
            "53:53/tcp"
            "${cfg.domain}:53:53/udp"
            "${toString cfg.dockerPort}/tcp"
          ];
          environment = cfg.environment;
          volumes = [
            "${service}-etc-pihole:/etc/pihole"
            "${service}-etc-dnsmasq.d:/etc/dnsmasq.d"
          ] ++ lib.optionals (cfg.environment.WEBPASSWORD_FILE != null) [
            "${cfg.environment.WEBPASSWORD_FILE}:${cfg.environment.WEBPASSWORD_FILE}"

          ];
          restart = cfg.restart;
          networks.${cfg.network.name}.ipv4_address = SERVICE_IP;
        };

      };
      volumes = {
        "${service}-etc-pihole" = { };
        "${service}-etc-dnsmasq.d" = { };
      };
      networks."${cfg.network.name}".external = true;
    };
  };
in
{
  options.x3framework.docker.services.pi-hole = with lib ;{
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
    domain = mkOption {
      type = types.str;
      description = mdDoc "Domain name of the pi-hole server. Additional domains can be added to services.nginx.virtualHosts.piHoleLAN.serverAliases";
      example = "192.168.0.10";
    };
    LANSubnet = mkOption {
      type = types.str;
      default = "192.168.0.0/24";
      description = mdDoc "Subnet of the local network, to be used to restrict local access to the web interface only.";
    };
    image = mkOption {
      type = types.str;
      description = mdDoc "Image for the container";
      default = "pihole/pihole:latest";
    };
    restart = mkOption {
      type = types.str;
      description = mdDoc "Restart directive for the container";
      default = "unless-stopped";
    };
    hostPort = mkOption {
      type = types.int;
      default = 5678;
      description = mdDoc "Port for nginx to listen to forward to the web interface";
    };
    dockerPort = mkOption {
      type = types.int;
      default = 80;
      description = mdDoc "Port for the docker container";
    };
    enableDNSFirewall = mkOption {
      type = types.bool;
      default = true;
      description = mdDoc "Add extra firewall rules on port 53 to disallow external IP access";

    };
    environment = mkOption {
      type = types.attrs;
      description = mdDoc "Environment variables for the docker container. Recommended are TZ, WEBPASSWORD_FILE, FTLCONF_LOCAL_IPV4. More info at https://github.com/pi-hole/docker-pi-hole .";
    };
    network = mkOption {
      type = lib.x3framework.types.x3NetworkType;
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
      {
        assertion = config.services.nginx.enable;
        message = "The nginx must be enabled to use this";
      }
    ];

    networking.firewall = mkIf cfg.enableDNSFirewall (firewallCommands cfg);

    x3framework.helper.${service}.composeFile = composeFile;
    services.nginx.virtualHosts =
      {
        piHoleLAN = {
          listen = [
            {
              addr = cfg.domain;
              port = cfg.hostPort;
              ssl = false;
            }
          ];
          http2 = true;
          serverName = cfg.domain;
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
    systemd.services."${service}-x3framework" = mkIf cfg.enableSystemd (import ./mkSystemdUnit.nix { inherit config docker service composeFile; network = cfg.network; });
  };
}

