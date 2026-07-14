{ lib, config, username, ... }:

let
  cfg = config.my.apps.onepassword;

  renderVault = { vault, item ? null }:
    "[[ssh-keys]]\n"
    + lib.optionalString (item != null) "item = \"${item}\"\n"
    + "vault = \"${vault}\"\n";
in
{
  options.my.apps.onepassword = {
    enable   = lib.mkEnableOption "1Password password manager";
    sshAgent = {
      enable = lib.mkEnableOption "1Password SSH agent";
      vaults = lib.mkOption {
        default     = [];
        description = "List of vaults to load SSH keys from";
        type        = lib.types.listOf (lib.types.submodule {
          options = {
            vault = lib.mkOption { type = lib.types.str; };
            item  = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
          };
        });
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      homebrew.casks = [ "1password" ];
    }

    (lib.mkIf cfg.sshAgent.enable {
      home-manager.users.${username} = { ... }: {
        xdg.configFile."1Password/ssh/agent.toml".text =
          lib.concatMapStrings renderVault cfg.sshAgent.vaults;
      };
    })
  ]);
}
