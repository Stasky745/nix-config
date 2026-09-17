{ lib, config, pkgs, username, ... }:

let
  cfg      = config.my.apps.zed;
  bundleId = "dev.zed.Zed";
in
{
  options.my.apps.zed = {
    enable        = lib.mkEnableOption "Zed editor";
    defaultEditor = lib.mkEnableOption "set as default editor (public.plain-text, public.source-code, $EDITOR)";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      homebrew.casks = [ "zed" ];

      home-manager.users.${username} = { ... }: {
        xdg.configFile."zed/themes/github_dark_stasky.yaml".source = ./themes/github_dark_stasky.yaml;

        xdg.configFile."zed/settings.json".text = builtins.toJSON {
          theme = {
            mode  = "dark";
            dark  = "GitHub Dark Stasky";
            light = "GitHub Dark Stasky";
          };

          agent_servers = {
            claude-acp = {
              type = "registry";
            };
          };

          agent = {
            dock = "right";
            sidebar_side = "right";
          };

          project_panel = {
            dock = "left";
          };

          git_panel = {
            dock = "left";
          };

          outline_panel = {
            dock = "left";
          };
        };
      };
    }

    (lib.mkIf cfg.defaultEditor {
      home-manager.users.${username} = { lib, ... }: {
        home.sessionVariables.EDITOR = "zed --wait";

        home.activation.setDefaultEditor = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${pkgs.duti}/bin/duti -s ${bundleId} public.plain-text  all 2>/dev/null || true
          ${pkgs.duti}/bin/duti -s ${bundleId} public.source-code all 2>/dev/null || true
        '';
      };
    })
  ]);
}
