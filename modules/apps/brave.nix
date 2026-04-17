{ lib, config, pkgs, username, ... }:

let
  cfg = config.my.apps.brave;
in
{
  options.my.apps.brave = {
    enable         = lib.mkEnableOption "Brave browser";
    dock           = lib.mkEnableOption "pin to dock" // { default = true; };
    defaultBrowser = lib.mkEnableOption "set as default browser";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      homebrew.casks = [ "brave-browser" ];

      system.defaults.dock.persistent-apps = lib.mkIf cfg.dock [ "/Applications/Brave Browser.app" ];
    }

    (lib.mkIf cfg.defaultBrowser {
      home-manager.users.${username} = { lib, ... }: {
        home.activation.setDefaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${pkgs.duti}/bin/duti -s com.brave.Browser http
          ${pkgs.duti}/bin/duti -s com.brave.Browser https
          ${pkgs.duti}/bin/duti -s com.brave.Browser public.html
        '';
      };
    })
  ]);
}
