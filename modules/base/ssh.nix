{ lib, config, username, ... }:

let
  cfg = config.my.base.ssh;

  configText =
    lib.concatMapStrings (p: "Include ${p}\n") cfg.extraIncludes
    + (if cfg.extraIncludes != [] then "\n" else "")
    + "Host *\n"
    + "  User ${cfg.username}\n"
    + "  ForwardAgent no\n"
    + "  Compression yes\n"
    + "  ServerAliveInterval 60\n"
    + "  AddKeysToAgent yes\n"
    + lib.optionalString cfg.use1PasswordAgent
        "  IdentityAgent \"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"\n"
    + lib.concatStringsSep "" (lib.mapAttrsToList (k: v: "  ${k} ${v}\n") cfg.globalOptions)
    + lib.optionalString (cfg.extraConfig != "") "\n${cfg.extraConfig}\n";
in
{
  options.my.base.ssh = {
    enable            = lib.mkEnableOption "SSH configuration";
    username          = lib.mkOption { type = lib.types.str; default = username; };
    extraIncludes     = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
    use1PasswordAgent = lib.mkEnableOption "1Password SSH agent socket as IdentityAgent";
    globalOptions     = lib.mkOption { type = lib.types.attrsOf lib.types.str; default = {}; };
    extraConfig       = lib.mkOption { type = lib.types.lines; default = ""; };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = { ... }: {
      home.file.".ssh/config" = {
        text = configText;
        mode = "0600";
      };
    };
  };
}
