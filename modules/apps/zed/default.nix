{ lib, config, username, ... }:

let
  cfg = config.my.apps.zed;
in
{
  options.my.apps.zed = {
    enable = lib.mkEnableOption "Zed editor";
  };

  config = lib.mkIf cfg.enable {
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
  };
}
