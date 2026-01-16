{ config, lib, pkgs, ... }:

let
  # Automatically import all .sh files from the functions.d directory
  functionsDir = ./functions.d;

  # Read all entries in the functions.d directory
  entries = builtins.readDir functionsDir;

  # Filter for .sh files
  shellFiles = lib.filterAttrs (name: type:
    type == "regular" && lib.hasSuffix ".sh" name
  ) entries;

  # Read and concatenate all shell function files
  functionContents = lib.concatMapStringsSep "\n\n" (
    filename: builtins.readFile (functionsDir + "/${filename}")
  ) (builtins.attrNames shellFiles);
in
{
  programs.zsh.initContent = functionContents;
}
