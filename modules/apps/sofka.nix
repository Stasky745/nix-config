{ lib, config, pkgs, username, ... }:

let
  cfg = config.my.apps.sofka;
in
{
  options.my.apps.sofka.enable = lib.mkEnableOption "sofka Kubernetes TUI";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.home.packages = [ pkgs.sofka ];
  };
}
