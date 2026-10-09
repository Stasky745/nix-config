{ lib, config, username, ... }:

let
  cfg = config.my.apps.sofka;
in
{
  options.my.apps.sofka.enable = lib.mkEnableOption "sofka Kubernetes TUI";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = { inputs, system, ... }: {
      # inputs.sofka.packages.${system}.sofka (built against sofka's own pinned
      # nixpkgs), not pkgs.sofka via an overlay — see flake.nix's sofka input.
      home.packages = [ inputs.sofka.packages.${system}.sofka ];
    };
  };
}
