{ lib, config, pkgs, username, ... }:

let
  cfg = config.my.apps.python;
in
{
  options.my.apps.python.enable = lib.mkEnableOption "Python 3 (nixpkgs)";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.home.packages = [ pkgs.python3 ];
  };
}
