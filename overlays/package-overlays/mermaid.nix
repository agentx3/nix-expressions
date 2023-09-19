{ pkgs }:

let mermaidcli = pkgs.nodePackages.mermaid-cli; in
mermaidcli.overrideAttrs (old: {
  nativeBuildInputs = old.nativeBuildInputs or [ ] ++ [
    pkgs.makeWrapper
    pkgs.which
  ];

  PUPPETEER_SKIP_CHROMIUM_DOWNLOAD = 1;

  nixpkgsChromePuppeteerConfig = pkgs.writeText "puppeteerConfig.json" ''
    { "executablePath": "${pkgs.chromium}/bin/chromium", "headless": "new" }
  '';

  postInstall = old.postInstall or "" + ''
    mv $out/bin/mmdc $out/bin/mmdc-script
    NODE=$(readlink -f $(which node))
    cat > $out/bin/mmdc <<EOF
    #!/usr/bin/env bash
    exec $out/bin/mmdc-script -p $nixpkgsChromePuppeteerConfig "\$@"
    EOF
    chmod +x $out/bin/mmdc
  '';

})
