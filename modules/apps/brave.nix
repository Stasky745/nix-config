{ lib, config, pkgs, username, ... }:

let
  cfg = config.my.apps.brave;
in
{
  options.my.apps.brave = {
    enable         = lib.mkEnableOption "Brave browser";
    defaultBrowser = lib.mkEnableOption "set as default browser";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      homebrew.casks = [ "brave-browser" ];
    }

    (lib.mkIf cfg.defaultBrowser {
      home-manager.users.${username} = { lib, ... }: {
        home.activation.setDefaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${pkgs.duti}/bin/duti -s com.brave.Browser http    2>/dev/null || true
          ${pkgs.duti}/bin/duti -s com.brave.Browser https   2>/dev/null || true
          ${pkgs.duti}/bin/duti -s com.brave.Browser public.html 2>/dev/null || true
        '';
      };
    })
  ]);
}
