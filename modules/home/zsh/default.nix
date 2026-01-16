{ config, lib, pkgs, ... }:

let
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
  imports = importAll ./config;

  # Base zsh configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # Autosuggestions configuration
    autosuggestion = {
      enable = true;
      highlight = "fg=#ffcc00";
      strategy = [ "history" ];
    };

    # Syntax highlighting
    syntaxHighlighting.enable = true;

    # Shell options and styles
    initContent = ''
      # Set cursor to steady bar (6)
      # Options: 1=blink block, 2=steady block, 3=blink underline, 4=steady underline, 5=blink bar, 6=steady bar
      echo -e "\033[6 q"

      # Enable comments in command line
      setopt interactivecomments
    '';
  };
}
