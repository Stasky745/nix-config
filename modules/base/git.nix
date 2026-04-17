{ lib, config, username, ... }:

let
  cfg = config.my.base.git;
in
{
  options.my.base.git = {
    enable = lib.mkEnableOption "git configuration";
    name   = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
    email  = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };

    sshOverHttps = lib.mkOption {
      type        = lib.types.listOf lib.types.str;
      default     = [ "github.com" "gitlab.com" "bitbucket.org" ];
      description = "Hosts to rewrite from HTTPS to SSH";
    };

    defaultBranch = lib.mkOption {
      type    = lib.types.str;
      default = "main";
    };

    extraConfig = lib.mkOption {
      type    = lib.types.attrs;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = { lib, ... }: {
      home.activation.gitLocalConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -f "$HOME/.gitconfig.local" ]; then
          echo ""
          echo "⚠ ~/.gitconfig.local not found. Create it with your git identity:"
          echo ""
          echo "  [user]"
          echo "    name  = Your Name"
          echo "    email = you@example.com"
          echo ""
        fi
      '';

      programs.git = {
        enable    = true;
        userName  = lib.mkIf (cfg.name  != null) cfg.name;
        userEmail = lib.mkIf (cfg.email != null) cfg.email;

        includes = [{ path = "~/.gitconfig.local"; }];

        extraConfig = {
          init.defaultBranch = cfg.defaultBranch;

          push = {
            default        = "current";
            autoSetupRemote = true;
          };

          pull.rebase = false;

          fetch.prune = true;

          rebase.autoStash = true;

          merge.conflictstyle = "zdiff3";

          diff = {
            algorithm = "histogram";
            colorMoved = "default";
          };

          color = {
            ui   = "always";
            diff = "always";
          };

          rerere.enabled = true;

          core.autocrlf = false;
        } // lib.listToAttrs (map (host: {
          name  = "url \"git@${host}:\"";
          value = { insteadOf = "https://${host}/"; };
        }) cfg.sshOverHttps)
          // cfg.extraConfig;
      };
    };
  };
}
