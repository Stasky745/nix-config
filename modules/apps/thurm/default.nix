{ lib, config, username, ... }:

let
  cfg = config.my.apps.thurm;
in
{
  # thurm has no cask/nixpkgs package yet on macOS (programs.thurm.package defaults to
  # null there — the app bundles its own thurm/thurmd) — install the app manually;
  # this module only manages its config via the programs.thurm home-manager module
  # (see hosts/darwin.nix's home-manager.sharedModules and the thurm flake input).
  options.my.apps.thurm.enable = lib.mkEnableOption "thurm terminal configuration";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = { ... }: {
      programs.thurm = {
        enable = true;

        # Matches modules/apps/ghostty/themes/mytheme and modules/apps/cmux/themes/mytheme.
        # Everything else is left at thurm's own defaults.
        settings.colors = {
          background            = "#14191e";
          foreground             = "#dbdbdb";
          cursor                 = "#fefffe";
          cursor_text            = "#000000";
          selection_background   = "#b3d7ff";
          selection_foreground   = "#000000";
          palette = [
            "#14191e" "#b43c29" "#00c200" "#c7c400"
            "#2743c7" "#bf3fbd" "#00c5c7" "#c7c7c7"
            "#676767" "#dc7974" "#57e690" "#ece100"
            "#a6aaf1" "#e07de0" "#5ffdff" "#feffff"
          ];
        };
      };
    };
  };
}
