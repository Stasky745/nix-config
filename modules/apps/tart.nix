{ lib, config, pkgs, username, ... }:

let
  cfg = config.my.apps.tart;
in
{
  options.my.apps.tart.enable = lib.mkEnableOption "tart macOS virtualisation";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.home.packages = [ pkgs.tart ];
  };
}
