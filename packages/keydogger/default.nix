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
    rev = "5ffd6790f3d3c8416f7d25ae890e09d9c92034b6";
    hash = "sha256-+JyEdnT02K7TIxxvvdd4/JLkm/SX5bEMYVjAPjSDUwU=";
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
