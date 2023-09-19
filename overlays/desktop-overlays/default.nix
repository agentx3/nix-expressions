let
  # These just create the desktop items
  desktopOverrides = final: prev: {
    # jamesdsp = import ./jamesdsp.nix { pkgs = prev; };
    # keepassxc = import ./keepassxc.nix { pkgs = prev; };
    plank = import ./plank.nix { pkgs = prev; };
    customDesktopItems = import ./desktopItems { pkgs = prev; };
  };
in
desktopOverrides

