{ pkgs }:
pkgs.jamesdsp.overrideAttrs (oldAttrs: {
  desktopItem = pkgs.makeDesktopItem {
    name = "jamesdsp";
    desktopName = "JamesDSP";
    genericName = "Audio effects processor";
    exec = "jamesdsp --tray";
    icon = "jamesdsp";
    comment = "JamesDSP for Linux";
    categories = [ "AudioVideo" "Audio" ];
    startupNotify = false;
    keywords = [ "equalizer" "audio" "effect" ];
  };
})
