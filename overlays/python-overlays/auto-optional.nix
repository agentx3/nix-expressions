{ typing-extensions, config, lib, python3Packages, buildPythonPackage, fetchFromGitHub, dataclasses }:

let
  typer = python3Packages.callPackage ./typer.nix { };
  libcst_0_3_23 = python3Packages.callPackage ./libcst_0_3_23.nix { };
in
with python3Packages;
buildPythonPackage rec {
  pname = "auto-optional";
  version = "0.3.2";

  src = fetchFromGitHub {
    owner = "Luttik";
    repo = "auto-optional";
    rev = "fa82574e9aabad7e69606b5a92df1e61a14ebe83";
    sha256 = "sha256-K3of/J1+3WCq+bgQi3kCRW3DhRrrm0j6KA8QniMZbpY=";
  };
  format = "pyproject";
  nativeBuildInputs = [
    poetry-core
    wrapPython
  ];

  propagatedBuildInputs = [
    typing-inspect
    typer
    pyyaml
    libcst_0_3_23
  ] ++ lib.optionals (pythonOlder "3.7") [ dataclasses ];



  postInstall = ''
    ls $out/
    echo "AAAAAAAAAAAAAAAAAAAAAAAAA"

  '';


  # doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/Luttik/auto-optional";
    description = "Makes typed arguments Optional when the default argument is None ";
    license = licenses.mit;
    maintainers = with maintainers; [ agentx3 ];
  };
}
