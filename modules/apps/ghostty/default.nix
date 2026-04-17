{ lib, config, username, ... }:

let
  cfg = config.my.apps.ghostty;
in
{
  options.my.apps.ghostty = {
    enable = lib.mkEnableOption "ghostty terminal emulator";
    dock   = lib.mkEnableOption "pin to dock" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    homebrew.casks = [ "ghostty" ];

    system.defaults.dock.persistent-apps = lib.mkIf cfg.dock [ "/Applications/Ghostty.app" ];

    home-manager.users.${username} = { ... }: {
      xdg.configFile."ghostty/config".source            = ./config;
      xdg.configFile."ghostty/themes/mytheme".source    = ./themes/mytheme;
    };
  };
}
