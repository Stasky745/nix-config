{ lib, config, ... }:

let
  cfg = config.my.apps.onepassword;
in
{
  options.my.apps.onepassword = {
    enable = lib.mkEnableOption "1Password password manager";
    dock   = lib.mkEnableOption "pin to dock" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    homebrew.casks = [ "1password" ];

    system.defaults.dock.persistent-apps = lib.mkIf cfg.dock [ "/Applications/1Password.app" ];
  };
}
