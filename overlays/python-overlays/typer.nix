{ typing-extensions, config, lib, python3Packages, buildPythonPackage, fetchFromGitHub, pkgs }:

with python3Packages;
buildPythonPackage {
  pname = "typer";
  version = "0.4.2";

  src = fetchFromGitHub {
    owner = "tiangolo";
    repo = "typer";
    rev = "d9b17883e36c5a43835347e54ef3ca9100b125e6";
    sha256 = "sha256-EzBkojsd59n1Y/VRF+2z1rUApGv4vMsHnQT2YsTGUPg=";
  };
  format = "pyproject";
  nativeBuildInputs = [
  ];
  propagatedBuildInputs = [
    poetry-core
    click
    flit-core
  ];

  postInstall = ''
    ls $out/
    echo "AAAAAAAAAAAAAAAAAAAAAAAAA"
  '';


  # doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/tiangolo/typer";
    description = "Typer, build great CLIs. Easy to code. Based on Python type hints. ";
    license = licenses.mit;
    maintainers = with maintainers; [ agentx3 ];
  };
}
