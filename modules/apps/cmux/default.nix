{ lib, config, username, ... }:

let
  cfg            = config.my.apps.cmux;
  ghosttyEnabled = config.my.apps.ghostty.enable;
in
{
  options.my.apps.cmux = {
    enable            = lib.mkEnableOption "cmux terminal emulator";
    claudeIntegration = lib.mkEnableOption "reminder to set up the oh-my-claudecode (OMC) integration" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    homebrew.casks = [ "cmux" ];

    home-manager.users.${username} = { lib, ... }: {
      xdg.configFile = lib.mkIf (!ghosttyEnabled) {
        "ghostty/config".source         = ./config;
        "ghostty/themes/mytheme".source = ./themes/mytheme;
      };

      home.activation.cmuxSetup = lib.mkIf cfg.claudeIntegration (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if [ ! -d "$HOME/.cmuxterm" ]; then
            echo ""
            echo "⚠ oh-my-claudecode (OMC) not set up. To enable the cmux Claude Code integration, run:"
            echo ""
            echo "  npm install -g oh-my-claude-sisyphus"
            echo "  cmux omc"
            echo ""
          fi
        ''
      );
    };
  };
}
