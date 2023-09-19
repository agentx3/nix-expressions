{ config, lib, python3Packages, buildPythonPackage, fetchPypi }:

with python3Packages;
buildPythonPackage rec {
  pname = "virtualfish";
  version = "2.5.5";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-a2VJlfFRr4/KYmRtSaYrW/ZGUUJQ8UYd9tQhR5laDbI=";
  };
  format = "pyproject";
  propagatedBuildInputs = [
    virtualenv
    psutil
    pkgconfig
    setuptools
    packaging
    poetry-core
  ];
  preInstall = ''
    mkdir -p $out/temp_home
    export HOME=$out/temp_home
  '';

  postInstall = ''
    export XDG_CONFIG_HOME="$HOME"
    $out/bin/vf install
    echo "AAAAAAAAAAAAAAAAAAAAAAAAA"
    ls $HOME
    echo "AAAAAAAAAAAAAAAAAAAAAAAAA"

  '';


  # doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/justinmayer/virtualfish";
    description = "VirtualFish is a Python virtual environment manager for the Fish shell.";
    license = licenses.mit;
    maintainers = with maintainers; [ justinmayer ];
  };
}
