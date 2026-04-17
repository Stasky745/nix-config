{ lib, config, ... }:

let
  cfg = config.my.apps.onepassword;
in
{
  options.my.apps.onepassword.enable = lib.mkEnableOption "1Password password manager";

  config = lib.mkIf cfg.enable {
    homebrew.casks = [ "1password" ];

    system.defaults.dock.persistent-apps = [ "/Applications/1Password.app" ];
  };
}
