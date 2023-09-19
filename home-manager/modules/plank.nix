{ config, lib, pkgs, ... }:
with lib;
let

  cfg = config.programs.plank;

  themeSubmodule = types.submodule ({ ... }: {
    options = {
      name = mkOption {
        type = types.str;
        default = "Default";
        description = "The name of the theme to use";
      };
      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        description = "The package to use for the theme";
      };
    };
  });
  docksSubmodule = types.submodule ({ ... }: {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Enable the dock";
      };
      name = mkOption {
        type = types.str;
        default = "dock1";
        description = "The name of the dock. Should be 'dock1', 'dock2', etc.";
      };
      extraDconfSetting = mkOption {
        type = types.attrs;
        default = { };
        example = {
          "alignment" = "center";
          "zoom-enabled" = true;
          "zoom-percent" = 128;
        };
        description =
          "Extra dconf settings for the dock. Should be in the same format as dconf settings";
      };
      pinned = mkOption {
        type = types.listOf (types.either types.package types.attrs);
        default = [ ];
        example = [
          geeqie
          (gnome.gnome-terminal.override (old: { pname = "org.gnome.Terminal"; }))
          {
            name = "nemo";
            desktopLocation = "/run/current-system/sw/share/applications/nemo.desktop";
          }

        ];
        description = lib.mdDoc
          "The items to be pinned in the dock. Some packages may not work with this setting as their desktop item name deviates from their package name. In such event, you try manually pinning the application and looking at the created .dockitem, and then creating an override for the package this list with the fixed pname. It is also possible to override the package for a specific location to avoid generating multiple files for it by providing its containing directory as well.";
      };
      theme = mkOption {
        type = types.nullOr themeSubmodule;
        default = cfg.theme;
        description = "The theme to use for the individual dock. Defaults to the top-level theme.";
      };

    };
  });
  DesktopFileLocations = pkg:
    let
      pkgName = _pkg: _pkg.pname or _pkg.name;
      fullDesktopPath = path: path + "/${pkgName pkg}.desktop";
      pkgInHomePackages = any (p: pkgName p == pkgName pkg) config.home.packages;
    in
    if pkg ? desktopLocation then [ pkg.desktopLocation ] else
    map fullDesktopPath (if pkgInHomePackages then
      cfg.userDesktopPaths
    else
      cfg.systemDesktopPaths);

  foldLists = lists: foldl' (a: b: a ++ b) [ ] lists;
  mkDockItemPath = dockName: index: pkg: path: {
    # We need to check multiple locations sometimes because there's really no guessing where the desktop file will be sometimes. If the desktop file is non-existent, the file will be created but won't appear on the dock so it's fine ¯\_(ツ)_/¯
    name = "${config.xdg.configHome}/plank/${dockName}/launchers/${pkg.pname or pkg.name}.dockitem";
    value = {
      text = ''
        [PlankDockItemPreferences]
        Launcher=file://${path}
      '';
    };
  };
  mkDockItemVariations = dockName: pkg:
    imap (index: path: mkDockItemPath dockName index pkg path) (DesktopFileLocations pkg);

  mkDockItems = dock: foldLists (map (mkDockItemVariations dock.name) dock.pinned);

  mkPlankTheme = theme:
    if theme != null then {
      "${theme.package.pname}" = {
        source = "${theme.package}/share/${theme.name}";
        target = "${config.xdg.dataHome}/plank/themes/${theme.name}";
      };
    } else { };

  mkPinnedDconfSetting = dock: {
    name = "dock-items";
    # value = map (p: (strings.getName (p.name or p.pname)) + ".dockitem") dock.pinned;
    # value = ''[${ strings.concatMapStringsSep "," (p: "'${strings.getName (p.name or p.name)}.dockitem'") dock.pinned }];
    value = hm.gvariant.mkArray hm.gvariant.type.string (map (p: ("${strings.getName (p.name or p.name)}.dockitem")) dock.pinned);
  };

  mkThemeDconfSetting = dock:
    if dock.theme != null then {
      name = "theme";
      value = "${dock.theme.name}";
    } else { };

  mkDconfSetting = dock: {
    name = "net/launchpad/plank/docks/${dock.name}";
    value = (listToAttrs ([ (mkThemeDconfSetting dock) ] ++ [ (mkPinnedDconfSetting dock) ])) // dock.extraDconfSetting;
    # value = (listToAttrs ([ (mkThemeDconfSetting dock) ] ++ [ (mkPinnedDconfSetting dock) ])) // dock.extraDconfSetting;
  };
  # mkDconfSettings = docks: map mkDconfSetting docks;
  # mkDconfSettings = docks: listToAttrs (map mkDconfSetting (attrValues docks));
  mkDconfSettings = docks: listToAttrs (map mkDconfSetting docks);
  mkAllDockItems = docks: listToAttrs (foldLists (map mkDockItems (attrValues docks)));

  mkAutoStart = enabled:
    if enabled then {
      "${config.xdg.configHome}/autostart/${cfg.package.pname}.desktop" = {
        text = (pkgs.makeDesktopItem {
          name = "plank";
          exec = "plank";
          icon = "plank";
          desktopName = "plank";
          genericName = ''A simple dock for the X Window System'';
          categories = [ "Utility" "Qt" ];
          mimeTypes = [ "application/x-plank" ];
        }).text;
      };
    } else { };

in
{
  options = {
    programs.plank = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable the plank dock";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.plank;
        defaultText = literalExpression "pkgs.plank";
        description = lib.mdDoc "The plank dock package";
      };
      docks = mkOption {
        # This should be an attrset of attresets with keys of the pattern "dock1" "dock2" etc.
        default = { };
        description = lib.mdDoc "The docks to configure";
        type = types.attrsOf docksSubmodule;
      };
      extraPackages = mkOption {
        type = types.listOf types.package;
        default = [ pkgs.bamf ];
        description = lib.mdDoc
          "Extra packages to be installed for the dock. bamf is sometimes needed for it to detect working processes.";
      };
      theme = mkOption {
        type = types.nullOr themeSubmodule;
        default = null;
        description = lib.mdDoc
          "The theme of the dock. Requires both the package and the name of the theme.";
      };
      systemDesktopPaths = mkOption {
        type = types.listOf types.path;
        default = [ "/run/current-system/sw/share/applications" ];
        description = lib.mdDoc "The paths to the system desktop files. Used to find the desktop files for the pinned items that are installed on the system level instead of the user level.";
      };
      userDesktopPaths = mkOption {
        type = types.listOf types.path;
        default = [
          "${config.home.homeDirectory}/.nix-profile/share/applications"
        ];
        description = lib.mdDoc "The paths to the user desktop files. Used to find the desktop files for the pinned items that are installed on the user level instead of the system level.";
      };
      autoStart = mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Whether to start the dock on startup";
      };
    };
  };
  config = (mkIf cfg.enable {
    home.packages = [ cfg.package ] ++ cfg.extraPackages;
    home.file = mkAllDockItems cfg.docks // mkPlankTheme cfg.theme // mkAutoStart cfg.autoStart;
    dconf.settings = mkDconfSettings (attrValues cfg.docks);
    # home.activation.Reload_Plank = hm.dag.entryAfter [ "linkGeneration" ] ''
    #   ${pkgs.killall}/bin/killall -q plank
    # '';
  });
}

