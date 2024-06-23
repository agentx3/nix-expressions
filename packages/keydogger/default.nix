{ fetchFromGitHub
, stdenv
, wl-clipboard
, lib
}: stdenv.mkDerivation {
  pname = "keydogger";
  version = "2.1";
  src = fetchFromGitHub {
    owner = "jarusll";
    repo = "keydogger";
    rev = "781bbcd328fe8ff1fff237248922780ea0128dbf";
    hash = "sha256-XTwkvkTJzgnEmBhW0IqmEKshcOf/SPBU2tMV7BDD0YE=";
  };
  strictDeps = true;
  buildInputs = [ wl-clipboard ];
  patches = [
    ./1.patch
  ];
  installPhase = ''
    ls -la
    mkdir -p $out/bin
    mv keydogger $out/bin
  '';

  meta = with lib; {
    homepage = "https://github.com/jarusll/keydogger";
    description = "Keydogger is a tiny text expander written in C ";
    license = licenses.mit;
    maintainers = with maintainers; [ agentx3 ];
    platforms = platforms.unix;
  };
}
