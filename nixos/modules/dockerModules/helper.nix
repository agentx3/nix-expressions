{ config, lib, pkgs, ... }:
with lib;
let

  cfg = config.x3framework;
  docker = "${ config.virtualisation.docker.package }/bin/docker";
  # Path is relative to /etc
  # helperDir = "x3framework/docker";
  helperModule = with types;
    types.submodule ({ ... }: {
      options = {
        name = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Name of the service";
        };
        composeFile = mkOption {
          type = nullOr (oneOf [ path pathInStore ]);
          description = "Location of the compose file";
        };
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable helper script";
        };
      };
    });

  parseHelperList = l: mapAttrsToList (n: v: if (v.enable) then (if (!isNull v.name) then v.name else n) else null) l;
  helperList = l: remove null (parseHelperList l);
  helperNames = helperList cfg.helper;
  mkScriptFile = serviceName:
    let
      script =
        let
          composeFile = cfg.helper.${serviceName}.composeFile;
        in
        pkgs.writeScript serviceName /* bash */ ''
          compose="${composeFile}"
          command="${docker} compose -f $compose -p ${serviceName}"
          usage() {
          cat <<EOF
          Commands:
          up      | Spin up all containers
          update  | Update all containers
          down    | Shutdown all containers
          restart | Restart all containers
          build   | Build main container
          logs    | Show logs
          sh      | Execute /bin/sh inside main container as root
          bash    | Execute /bin/bash inside main container as root
          help    | Display this help text
          EOF
          }
          case $1 in
          up) $command up -d;;
          update) $command pull; $command up -d --force-recreate;;
          down) $command down;;
          restart) $command restart;;
          build) $command build ${serviceName};;
          logs) $command logs -f --tail 100;;
          sh) $command exec ${serviceName} sh;;
          bash) $command exec ${serviceName} bash;;
          help) usage;;
          *) echo "E: Invalid Command"; echo; usage; exit 1;;
          esac
        '';
    in
    "${script}";
  mkAliases = a: genAttrs a (scriptName: (mkScriptFile scriptName));
  mkScriptFiles = names: lib.foldl' (a: b: a // b) { } (map mkScriptFile names);

in
{
  options.x3framework.helper = mkOption {
    default = { };
    type = types.attrsOf helperModule;
    description = lib.mdDoc "Helper script for docker compose";
  };

  config = {
    # Script alias
    programs.fish.shellAliases = mkAliases helperNames;
    # Maintenance script template
    # environment.etc = mkScriptFiles helperNames;
  };
}
