{ pkgs }:
let
  inherit (pkgs) callPackage;
in
{

  frankendrift = callPackage ./frankendrift { };
  pycln = pkgs.python310Packages.callPackage ./pycln { };
  gocv = callPackage ./goPackages/gocv { };
  fblitz = callPackage ./goPackages/fblitz { };
  keydogger = callPackage ./keydogger { };
}
