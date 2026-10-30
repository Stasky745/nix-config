{ config, lib, pkgs, ... }:

let
  # Every .sh file in scripts.d becomes a command on PATH named after the file
  scriptsDir = ./scripts.d;

  shellFiles = lib.filterAttrs (name: type:
    type == "regular" && lib.hasSuffix ".sh" name
  ) (builtins.readDir scriptsDir);
in
{
  home.packages = lib.mapAttrsToList (filename: _:
    pkgs.writeShellApplication {
      name = lib.removeSuffix ".sh" filename;
      text = builtins.readFile (scriptsDir + "/${filename}");
    }
  ) shellFiles;
}
