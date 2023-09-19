{ lib, config, ... }:
with lib;
let
  inherit (lib) mkIf mkOption;
  cfg = config.autostart;
  autoStartDirectory = "${config.xdg.configHome}/autostart/";
  mkAutoStart = (pkg:
    if true then
      {
        name = autoStartDirectory + pkg.pname + ".desktop";
        value =
          if pkg ? desktopItem then {
            text = pkg.desktopItem.text;
          }
          else {
            source = (pkg + "/share/applications/" + pkg.pname or pkg.name + ".desktop");
          };
      } else null);
in
{
  options = {
    autostart = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        Installs the package and creates desktop files in the autostart directory. The packages in this list must not also be included in the home.packages list
      '';
    };
  };
  config = mkMerge [
    (mkIf (cfg != [ ]) {
      # home.packages = cfg;
      home.file = listToAttrs (filter (n: n != null) (map (pkg: mkAutoStart pkg) cfg));
    })
  ];
}
 
