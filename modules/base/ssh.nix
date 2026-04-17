{ lib, config, username, ... }:

let
  cfg = config.my.base.ssh;
in
{
  options.my.base.ssh = {
    enable      = lib.mkEnableOption "SSH configuration";
    username    = lib.mkOption {
      type        = lib.types.str;
      default     = username;
      description = "SSH username for remote hosts";
    };
    extraIncludes = lib.mkOption {
      type        = lib.types.listOf lib.types.str;
      default     = [];
      description = "Paths prepended as Include directives at the top of the SSH config";
    };
    globalOptions = lib.mkOption {
      type        = lib.types.attrsOf lib.types.str;
      default     = {};
      description = "Extra options merged into the Host * block";
    };
    extraConfig = lib.mkOption {
      type        = lib.types.lines;
      default     = "";
      description = "Additional SSH config appended after all blocks";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = { ... }: {
      programs.ssh = {
        enable              = true;
        compression         = true;
        serverAliveInterval = 60;

        includes = cfg.extraIncludes;

        matchBlocks = {
          "*" = {
            user           = cfg.username;
            forwardAgent   = false;
            identitiesOnly = true;
            extraOptions   = { AddKeysToAgent = "yes"; } // cfg.globalOptions;
          };
        };

        extraConfig = cfg.extraConfig;
      };
    };
  };
}
