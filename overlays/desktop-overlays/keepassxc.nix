{ pkgs }:
pkgs.keepassxc.overrideAttrs (oldAttrs: {
  desktopItem = pkgs.makeDesktopItem {
    name = "keepassxc";
    exec = "keepassxc %f";
    icon = "keepassxc";
    desktopName = "KeepassXC";
    genericName = ''Community-driven port of the Windows application “KeePass Password Safe”'';
    categories = [ "Utility" "Security" "Qt" ];
    mimeTypes = [ "application/x-keepass2" ];
  };
})
