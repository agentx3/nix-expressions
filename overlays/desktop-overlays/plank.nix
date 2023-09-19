{ pkgs }:
pkgs.plank.overrideAttrs (oldAttrs: {
  desktopItem = pkgs.makeDesktopItem {
    name = "plank";
    exec = "plank";
    icon = "plank";
    desktopName = "plank";
    genericName = ''A simple dock for the X Window System'';
    categories = [ "Utility" "Qt" ];
    mimeTypes = [ "application/x-plank" ];
  };
})
