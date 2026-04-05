{
  description = "Nix Configuration";

  inputs = {
    nixpkgs.url        = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # MailerLite shared configuration
    mailerlite = {
      url = "path:/Users/rocriberablasi/.config/mailerlite/nix-config";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };
  };

  outputs = inputs@{ nixpkgs, ... }:
    let
      # Auto-discover all subdirectories of modules/ by name.
      # Adding a new category (e.g. modules/services/) makes it available
      # as `modules.services` in every host's imports.nix automatically.
      modules = builtins.mapAttrs
        (name: _: ./modules/${name})
        (builtins.readDir ./modules);
    in
    {
      darwinConfigurations = {
        RocsMacBookPro = import ./hosts/RocsMacBookPro/system.nix { inherit inputs modules; };
        vm             = import ./hosts/vm/system.nix             { inherit inputs modules; };
      };

      devShells."aarch64-darwin".default =
        nixpkgs.legacyPackages."aarch64-darwin".mkShell {
          buildInputs = [ nixpkgs.legacyPackages."aarch64-darwin".go-task ];
        };
    };
}
