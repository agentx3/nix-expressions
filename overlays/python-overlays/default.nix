final: prev:
{
  pythonPackagesOverlays = (prev.pythonPackagesOverlays or [ ]) ++ [
    (python-final: python-prev: {
      # cviz = python-final.callPackage cvizPkg { };
      # ...
      auto-optional = python-final.pythonPackages.callPackage ./auto-optional.nix { };
      typer = python-final.pythonPackages.callPackage ./typer.nix { };
      libcst_3_23 = python-final.pythonPackages.callPackage ./libcst_0_3_23.nix { };
      doq = python-final.python3Packages.callPackage ./doq.nix { };
    })
  ];

  python3 =
    let
      self = prev.python3.override {
        inherit self;
        packageOverrides = prev.lib.composeManyExtensions final.pythonPackagesOverlays;
      };
    in
    self;

  python3Packages = final.python3.pkgs;

}
