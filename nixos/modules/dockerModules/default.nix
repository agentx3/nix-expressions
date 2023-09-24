{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  imports = [
    ./helper.nix
    ./docker-network.nix
    ./x3-docker-network.nix
    ./services
  ];

  lib.x3framework = {
    mkDockerEnvVars =
      let
        mkAtL = a: lib.mapAttrsToList
          (n: v: ''
            - ${n}: "${v}"
          '')
          a
        ;
        mkCombine = lib.foldl' (a: b: a + b) "";
        mkEntries = a: mkCombine (mkAtL a);
      in
      mkEntries;
    mkIPFromSubnetAndSuffix = subnet: suffix:
      let
        splitSubnet = lib.splitString "." subnet;
        splitSubnetLen = lib.lists.count (_: true) splitSubnet;
        splitSuffix = lib.splitString "." suffix;
        splitSuffixLen = lib.lists.count (_: true) splitSuffix;
        diff = splitSubnetLen - splitSuffixLen;
        prefix = lib.take diff splitSubnet;
        network = lib.concatStringsSep "." (prefix ++ splitSuffix);
      in
      network;
    types.x3NetworkType =
      let
        x3Types = import ./types.nix { inherit lib; };
      in
      x3Types.x3NetworkType;
    mkSystemdUnit = import ./services/mkSystemdUnit.nix;

  };



}
