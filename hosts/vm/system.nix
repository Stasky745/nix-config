{ inputs, modules }:

let
  username = "stasky";
  system   = "aarch64-darwin";
in
inputs.nix-darwin.lib.darwinSystem {
  inherit system;
  specialArgs = { inherit inputs modules username system; };
  modules = [
    inputs.home-manager.darwinModules.home-manager
    ../darwin.nix
    ./imports.nix
    ./config.nix
  ];
}
