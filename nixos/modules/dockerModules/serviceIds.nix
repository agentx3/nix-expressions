{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkOption types mdDoc mkIf;
in
{
  # options.x3framework.docker.ser = {
  # };
  # config = mkIf cfg.enable {
  #   assertions = [
  #     {
  #       assertion = x3cfg.dockerNetwork.enable;
  #       message = "The framework's dockerNetwork must be enabled to use this";
  #     }
  #   ];

  #   x3framework.helper.${service}.composeFile = composeFile;

  #   systemd.services.roundcube-x3framework = import ./mkSystemdUnit.nix { inherit config docker service composeFile; };

  # };
}

