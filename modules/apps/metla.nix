{ lib, config, username, ... }:

let
  cfg = config.my.apps.metla;
in
{
  options.my.apps.metla = {
    enable = lib.mkEnableOption "metla git worktree sweeper";
    roots  = lib.mkOption {
      type    = lib.types.listOf lib.types.str;
      default = [ "~/repos" ];
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = { ... }: {
      programs.metla = {
        enable         = true;
        settings.roots = cfg.roots;
      };
    };
  };
}
