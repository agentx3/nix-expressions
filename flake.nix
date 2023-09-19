{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    }:
    flake-utils.lib.eachDefaultSystem (system:
    {
      nixosModules = rec {
        default = {
          imports = [
            ./nixos/modules
          ];
        };
        dockerModules = {
          imports = [
            ./nixos/modules/dockerModules
          ];
        };
        serviceModules = {
          imports = [
            ./nixos/modules/serviceModules
          ];
        };
      };
      hmModules = {
        imports = [
          ./home-manager/modules
        ];
      };
      overlays = {
        extraPackages = prev: final: self.packages;
      } // (import ./overlays);

      packages =
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./packages { inherit pkgs; };
    });
}
