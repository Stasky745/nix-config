{ lib, config, pkgs, username, ... }:

let
  cfg            = config.my.apps.cmux;
  ghosttyEnabled = config.my.apps.ghostty.enable;
  bundleId       = "com.cmuxterm.app";
in
{
  options.my.apps.cmux = {
    enable            = lib.mkEnableOption "cmux terminal emulator";
    claudeIntegration = lib.mkEnableOption "reminder to set up the oh-my-claudecode (OMC) integration" // { default = true; };
    defaultTerminal   = lib.mkEnableOption "set as default terminal (public.unix-executable, $TERMINAL)";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
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
    }

    (lib.mkIf cfg.defaultTerminal {
      home-manager.users.${username} = { lib, ... }: {
        home.sessionVariables.TERMINAL = "cmux";

        home.activation.setDefaultTerminal = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${pkgs.duti}/bin/duti -s ${bundleId} public.unix-executable all 2>/dev/null || true
        '';
      };
    })
  ]);
}
