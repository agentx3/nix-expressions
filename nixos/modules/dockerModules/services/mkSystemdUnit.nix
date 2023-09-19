{ config, service, docker, composeFile, network }:
{
  description = "This service unit controls the start and stop of the roundcube container.";
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    RemainAfterExit = true;
    Type = "oneshot";
    ProtectSystem = "strict";
    PrivateDevices = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    CapabilityBoundingSet = "";
    NoNewPrivileges = true;
    LockPersonality = true;
    RestrictRealtime = true;
    PrivateUsers = true;
    # MemoryDenyWriteExecute = true;
  };
  requires = [ "docker.service" "docker-network-${network.name}.service" ];
  after = [ "network.target" "docker.service" "docker-network-${network.name}.service" ];
  script = /* bash */ ''
    compose="${composeFile}"
    command="${docker} compose -f $compose -p ${service}"
    $command up -d
  '';
  preStop = /* bash */ ''
    compose="${composeFile}"
    command="${docker} compose -f $compose -p ${service}"
    $command down
  '';

}

