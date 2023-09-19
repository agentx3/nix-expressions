{ lib, python3Packages, buildPythonPackage, fetchPypi }:

with python3Packages;
buildPythonPackage rec {
  pname = "doq";
  version = "0.9.1";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-uszDSN35Z8i/Mr/fVNqDJuHcdPN4ZeLBdgEq0Lx+6h4=";
  };
    propagatedBuildInputs = [ toml parso jinja2 ];

  doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/heavenshell/py-doq";
    description = "Docstring generator.";
    license = licenses.bsd3;
    maintainers = with maintainers; [ heavenshell ];
  };
}
