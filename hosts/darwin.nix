{ username, system, inputs, lib, ... }:

let
  overlays = [
    inputs.sofka.overlays.default
    (final: _prev: {
      stable = import inputs.nixpkgs-stable {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    })
  ];
  enabled  = { enable = true; };
  disabled = { enable = false; };
in
{
  nixpkgs.hostPlatform       = system;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays           = overlays;

  # Determinate Nix manages the daemon and /etc/zshenv
  nix.enable          = false;
  programs.zsh.enable = false;

  users.users.${username}.home = "/Users/${username}";
  system.primaryUser           = username;
  system.stateVersion          = 6;

  _module.args = { inherit enabled disabled; };

  home-manager.useGlobalPkgs       = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs    = { inherit inputs username system enabled disabled; inherit (inputs) mailerlite; };
}
