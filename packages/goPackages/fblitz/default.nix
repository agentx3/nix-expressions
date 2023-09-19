{ buildGoModule
, lib
}:

buildGoModule {
  pname = "fblitz";
  version = "0.0.1";

  src = ./fblitz.tar.gz;

  checkRun = false;

  postInstall = ''
    mv $out/bin/blitzbidz $out/bin/fblitz
  '';
  # --prefix LD_LIBRARY_PATH : ${stdenv.lib.makeLibraryPath libs}


  vendorHash = "sha256-TvByKjMUqXu5hIo+X47YUlbT/zBZ/oMaB4HePMyaShg=";
  meta = with lib; {
    description = "A simple scraper search for blitzbidz";
    license = licenses.mit;
    maintainers = with maintainers; [ agentx3 ];
  };
}
