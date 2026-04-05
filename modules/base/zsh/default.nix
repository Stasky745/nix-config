{ config, lib, username, ... }:

let
  cfg = config.my.base.zsh;

  # Automatically import all .nix files from the config directory
  importAll = dir:
    let
      entries = builtins.readDir dir;
      nixFiles = lib.filterAttrs (name: type:
        type == "regular" &&
        lib.hasSuffix ".nix" name
      ) entries;
    in
    map (name: dir + "/${name}") (builtins.attrNames nixFiles);
in
{
  options.my.base.zsh.enable = lib.mkEnableOption "zsh shell configuration";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = { ... }: {
      # Import all config/ sub-modules within home-manager context
      imports = importAll ./config;

      programs.zsh = {
        enable = true;
        enableCompletion = true;

        autosuggestion = {
          enable = true;
          highlight = "fg=#ffcc00";
          strategy = [ "history" ];
        };

        syntaxHighlighting.enable = true;

        initContent = ''
          # Set cursor to steady bar (6)
          # Options: 1=blink block, 2=steady block, 3=blink underline, 4=steady underline, 5=blink bar, 6=steady bar
          echo -e "\033[6 q"

          # Enable comments in command line
          setopt interactivecomments
        '';
      };
    };
  };
}
