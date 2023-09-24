{ config, lib, pkgs, ... }:
with lib;

let

  service = "matomo";
  NGINX_IP4 = "120";
  IP4 = "121";
  DB_IP4 = "122";
  mkIp = config.lib.x3framework.mkIPFromSubnetAndSuffix;
  SERVICE_IP = mkIp cfg.network.subnetBase IP4;
  DATABASE_IP = mkIp cfg.network.subnetBase DB_IP4;
  NGINX_IP = mkIp cfg.network.subnetBase NGINX_IP4;
  cfg = config.x3framework.docker.services.${service};
  # DATA_DIR = "/data/${SERVICE}";
  matomoNginxConf = pkgs.writeTextFile {
    name = "matomo-nginx.conf";
    text = /* nginx */ ''
      upstream php-handler {
      	server ${SERVICE_IP}:9000;
      }

      server {
      	listen 80;
      	add_header Referrer-Policy origin; # make sure outgoing links don't show the URL to the Matomo instance
      	root /var/www/html; # replace with path to your matomo instance
      	index index.php;
      	try_files $uri $uri/ =404;

      	## only allow accessing the following php files
      	location ~ ^/(index|matomo|piwik|js/index|plugins/HeatmapSessionRecording/configs).php {
      		# regex to split $uri to $fastcgi_script_name and $fastcgi_path
      		fastcgi_split_path_info ^(.+\.php)(/.+)$;

      		# Check that the PHP script exists before passing it
      		try_files $fastcgi_script_name =404;

      		include fastcgi_params;
      		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
      		fastcgi_param PATH_INFO $fastcgi_path_info;
      		fastcgi_param HTTP_PROXY ""; # prohibit httpoxy: https://httpoxy.org/
      		fastcgi_pass php-handler;
      	}

      	## deny access to all other .php files
      	location ~* ^.+\.php$ {
      		deny all;
      		return 403;
      	}

      	## disable all access to the following directories
      	location ~ /(config|tmp|core|lang) {
      		deny all;
      		return 403; # replace with 404 to not show these directories exist
      	}
      	location ~ /\.ht {
      		deny all;
      		return 403;
      	}

      	location ~ js/container_.*_preview\.js$ {
      		expires off;
      		add_header Cache-Control 'private, no-cache, no-store';
      	}

      	location ~ \.(gif|ico|jpg|png|svg|js|css|htm|html|mp3|mp4|wav|ogg|avi|ttf|eot|woff|woff2|json)$ {
      		allow all;
      		## Cache images,CSS,JS and webfonts for an hour
      		## Increasing the duration may improve the load-time, but may cause old files to show after an Matomo upgrade
      		expires 1h;
      		add_header Pragma public;
      		add_header Cache-Control "public";
      	}

      	location ~ /(libs|vendor|plugins|misc/user) {
      		deny all;
      		return 403;
      	}

      	## properly display textfiles in root directory
      	location ~/(.*\.md|LEGALNOTICE|LICENSE) {
      		default_type text/plain;
      	}
      }
    '';
  };
  composeFile = pkgs.writeTextFile {
    name = "${service}-compose.yml";
    text = builtins.toJSON {
      version = "3.9";
      services = {
        "app" = {
          restart = "unless-stopped";
          container_name = "${service}";
          image = "matomo:fpm-alpine";
          environment = {
            MATOMO_DATABASE_HOST = "${service}-db";
            PHP_MEMORY_LIMIT = "2048M";
          } // cfg.environment;
          env_file = cfg.envFile;
          networks."${cfg.network.name}".ipv4_address = SERVICE_IP;
          volumes = [
            "${service}-html:/var/www/html"
          ];
          ports = [
            "9000"
          ];
        };
        "db" = {
          restart = "unless-stopped";
          container_name = "${service}-db";
          image = "mysql:8.0";
          command = "--max-allowed-packet=64MB  --local-infile=ON";
          env_file = cfg.envFile;
          environment = { } // cfg.environment;
          networks."${cfg.network.name}".ipv4_address = DATABASE_IP;
          volumes = [
            "${service}-data:/var/lib/mysql:Z"
          ];
        };
        web = {
          image = "nginx:alpine";
          restart = "unless-stopped";
          container_name = "${service}-web";
          volumes = [
            "${service}-html:/var/www/html:z,ro"
            "${matomoNginxConf}:/etc/nginx/conf.d/default.conf:z,ro"
          ];
          ports = [
            "80"
          ];
          networks."${cfg.network.name}".ipv4_address = NGINX_IP;
        };
      };
      volumes = {
        "${service}-data" = { };
        "${service}-html" = { };
      };
      networks."${cfg.network.name}".external = true;
    };
  };
in
{
  options.x3framework.docker.services.matomo = {
    enable = mkEnableOption "" // {
      description = ''
        Whether to enable the container task. Enable this if the configuration
        is deployed to a NixOS container.
      '';
    };
    containerIp = mkOption {
      type = types.str;
      default = SERVICE_IP;
      description = mdDoc "IP address of the container";
    };
    domain = mkOption {
      type = types.str;
      description = mdDoc "Domain name of the matomo server";
    };
    environment = mkOption {
      type = types.attrs;
      default = { };
      description = mdDoc "Additional environment variables to pass to the container";
    };
    envFile = mkOption {
      type = types.str;
      default = ''""'';
      description = mdDoc ''
        Environment file for the docker container. It should contain these variables:
        MYSQL_ROOT_PASSWORD=
        MYSQL_PASSWORD=
        MYSQL_DATABASE=
        MYSQL_USER=
        MATOMO_DATABASE_ADAPTER=
        MATOMO_DATABASE_TABLES_PREFIX=
        MATOMO_DATABASE_USERNAME=
        MATOMO_DATABASE_PASSWORD=
        MATOMO_DATABASE_DBNAME=

      '';
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
        message = "The framework's docker-network must be enabled to use this";
      }
    ];

    x3framework.helper.${service}.composeFile = composeFile;

    systemd.services.matomo-x3framework = config.lib.x3framework.mkSystemdUnit { inherit config service composeFile; network = cfg.network; };
    users.users.nginx.extraGroups = [ "82" ];

    services.nginx.virtualHosts.${service} = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 443;
          ssl = true;
        }
        {
          addr = "[::]";
          port = 443;
          ssl = true;
        }
      ];
      http2 = true;
      forceSSL = true;
      serverName = cfg.domain;
      sslCertificate = "/etc/letsencrypt/live/${cfg.domain}/fullchain.pem";
      sslCertificateKey = "/etc/letsencrypt/live/${cfg.domain}/privkey.pem";
      sslTrustedCertificate = "/etc/letsencrypt/live/${cfg.domain}/chain.pem";
      locations = {
        "/" = {
          extraConfig = /*nginx*/''
            proxy_pass               http://${NGINX_IP}:80;
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
}


