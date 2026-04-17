{ lib, config, username, ... }:

let
  cfg = config.my.apps.ghostty;
in
{
  options.my.apps.ghostty.enable = lib.mkEnableOption "ghostty terminal emulator";

  config = lib.mkIf cfg.enable {
    homebrew.casks = [ "ghostty" ];

    system.defaults.dock.persistent-apps = [ "/Applications/Ghostty.app" ];

    home-manager.users.${username} = { ... }: {
      xdg.configFile."ghostty/config".source            = ./config;
      xdg.configFile."ghostty/themes/mytheme".source    = ./themes/mytheme;
    };
  };
}
