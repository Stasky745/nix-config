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

  nix.settings = {
    substituters = [ "https://nkl-sofka.cachix.org" ];
    trusted-public-keys = [ "nkl-sofka.cachix.org-1:hLg9frFNJynrxe7SSBb/p6pbawlpZmG10bw+wLsTufw=" ];
  };

  # Skip generating the full nix-darwin/home-manager options reference
  # (man pages/HTML/JSON) on every switch — it can't be cached because it
  # includes the private `mailerlite` module tree, so it's rebuilt from
  # scratch locally every time and is the main driver of switch-time RAM use.
  documentation.enable = false;

  home-manager.sharedModules = [{
    manual.manpages.enable = false;
    manual.html.enable     = false;
    manual.json.enable     = false;

    # https://github.com/nix-community/home-manager/issues/8163 is fixed as of
    # this home-manager version — copyApps replaces the old linkApps symlink
    # trick and additionally makes nix-installed .app bundles Spotlight-searchable.
    targets.darwin.linkApps.enable = false;
    targets.darwin.copyApps.enable = true;
  }];

  users.users.${username}.home = "/Users/${username}";
  system.primaryUser           = username;
  system.stateVersion          = 6;

  _module.args = { inherit enabled disabled; };

  home-manager.useGlobalPkgs       = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs    = { inherit inputs username system enabled disabled; inherit (inputs) mailerlite; };
}
