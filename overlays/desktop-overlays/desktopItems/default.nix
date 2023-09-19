{ pkgs }:
{
  steam = pkgs.makeDesktopItem {
    name = "steam";
    exec = "env GDK_SCALE=2 steam";
    icon = "steam";
    desktopName = "steam";
    genericName = ''A gaming platform developed by Valve Software'';
    categories = [ "Game" ];
    mimeTypes = [ "application/x-steam" ];
  };
  keepassxc = pkgs.makeDesktopItem {
    name = "keepassxc";
    comment = ''Community-driven port of the Windows application "KeePass Password Safe"'';
    exec = "keepassxc %f";
    tryExec = "keepassxc";
    icon = "keepassxc";
    desktopName = "keepassxc";
    genericName = ''Password manager'';
    startupWMClass = "keepassxc";
    startupNotify = false;
    terminal = false;
    categories = [ "Utility" "Security" "Qt" ];
    mimeTypes = [ "application/x-keepass2" ];
  };
  discord = pkgs.makeDesktopItem {
    name = "discord";
    exec = "discord";
    icon = "discord";
    desktopName = "discord";
    genericName = ''All-in-one voice and text chat for gamers that's free, secure, and works on both your desktop and phone.'';
    categories = [ "Network" "InstantMessaging" "Qt" ];
    mimeTypes = [ "application/x-discord" ];
  };

  jamesdsp = pkgs.makeDesktopItem {
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

}
