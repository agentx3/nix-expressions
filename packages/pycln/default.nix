{ lib
, fetchFromGitHub
, poetry-core
, setuptools
, pytestCheckHook
, buildPythonPackage
, tomlkit
, typer
, pyyaml
, libcst
, pathspec
}:
buildPythonPackage rec {
  pname = "pycln";
  version = "2.1.5";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "hadialqattan";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-SXnteHsGCVfzC7SFJrnybqwv25dn1Gbg4VjLlpHiH+c=";
  };

  nativeBuildInputs = [
    poetry-core
    setuptools
  ];

  propagatedBuildInputs = [
    tomlkit
    libcst
    typer
    pathspec
    pyyaml
  ];

  nativeCheckInputs = [
    pytestCheckHook
  ];

  postCheck = ''
    # Confirm that the produced executable script is wrapped correctly and runs
    # OK, by launching it in a subshell without PYTHONPATH
    (
      unset PYTHONPATH
      echo "Testing that `pycln --version` returns OK..."
      $out/bin/pycln --version
    )
  '';

  preCheck = ''
    HOME=$TMPDIR
    export PATH=$PATH:$out/bin
  '';

  meta = with lib; {
    description = "A formatter for finding and removing unused import statements";
    homepage = "https://github.com/hadialqattan/pycln/";
    license = licenses.mit;
    maintainers = with maintainers; [ agentx3 ];
  };
}
