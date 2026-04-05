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
      xdg.configFile."ghostty/config".text = ''
        term = xterm-256color

        # Window
        confirm-close-surface = false
        background-opacity = 0.95
        window-theme = system

        # Typography
        font-family = Monaspace Neon
        font-size = 13

        # Font features
        font-feature = -liga
        font-feature = -calt
        font-feature = -dlig
      '';
    };
  };
}
