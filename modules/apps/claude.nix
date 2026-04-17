{ lib, config, pkgs, username, ... }:

let
  cfg = config.my.apps.claude;
in
{
  options.my.apps.claude = {
    desktop.enable = lib.mkEnableOption "Claude desktop app";
    desktop.dock   = lib.mkEnableOption "pin to dock" // { default = true; };
    code.enable    = lib.mkEnableOption "Claude Code CLI";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.desktop.enable {
      homebrew.casks = [ "claude" ];
      system.defaults.dock.persistent-apps = lib.mkIf cfg.desktop.dock [ "/Applications/Claude.app" ];
    })

    (lib.mkIf cfg.code.enable {
      home-manager.users.${username} = { ... }: {
        home.packages = [ pkgs.claude-code ];
      };
    })
  ];
}
