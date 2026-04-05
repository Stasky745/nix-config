{ inputs, modules }:

let
  username = "rocriberablasi";
  system   = "aarch64-darwin";
in
inputs.nix-darwin.lib.darwinSystem {
  inherit system;
  specialArgs = { inherit inputs modules username system; inherit (inputs) mailerlite; };
  modules = [
    inputs.home-manager.darwinModules.home-manager
    ../darwin.nix
    ./imports.nix
    ./config.nix
  ];
}
