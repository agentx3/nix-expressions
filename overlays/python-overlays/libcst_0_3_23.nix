{ config, lib, python3Packages, buildPythonPackage, fetchPypi }:

with python3Packages;
buildPythonPackage rec {
  pname = "libcst";
  version = "0.3.23";

  src = builtins.fetchurl
    "https://files.pythonhosted.org/packages/51/07/b24e2f08461eb9844e8d2c1c0b954050898766fd18a407af2b8376eef956/libcst-0.3.23-py3-none-any.whl";

  format = "wheel";

  nativeBuildInputs = [ setuptools pyyaml typing-inspect ];


  meta = with lib; {
    homepage = "https://github.com/Instagram/LibCST";
    description = "A concrete syntax tree with AST-like properties for Python 3.5, 3.6, 3.7 and 3.8 programs.";
    license = licenses.mit;
    maintainers = with maintainers; [ agentx3 ];
  };
}

