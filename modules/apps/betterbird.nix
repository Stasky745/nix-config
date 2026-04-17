{ lib, config, pkgs, username, ... }:

let
  cfg      = config.my.apps.betterbird;
  bundleId = "eu.betterbird.Betterbird";

  package = pkgs.stdenv.mkDerivation rec {
    pname   = "betterbird";
    version = "140.9.0esr-bb20";

    src = pkgs.fetchurl {
      url    = "https://www.betterbird.eu/downloads/MacDiskImage/betterbird-${version}.en-US.mac.dmg";
      sha256 = "sha256-v2dKoyGdMySiWyRdLPbJRjCe6ggpp4f0AZ/Fvyj1ALY=";
    };

    nativeBuildInputs = [ pkgs.undmg ];
    sourceRoot = ".";

    installPhase = ''
      mkdir -p "$out/Applications"
      cp -R Betterbird.app "$out/Applications/"
    '';
  };
in
{
  options.my.apps.betterbird = {
    enable                = lib.mkEnableOption "Betterbird email client";
    dock                  = lib.mkEnableOption "pin to dock" // { default = true; };
    defaultMailClient     = lib.mkEnableOption "set as default mail client";
    defaultCalendarClient = lib.mkEnableOption "set as default calendar client";
  };

  config = lib.mkIf cfg.enable {
    system.defaults.dock.persistent-apps = lib.mkIf cfg.dock [ "/Applications/Betterbird.app" ];

    home-manager.users.${username} = { lib, ... }: {
      home.packages = [ package ];

      home.activation.betterbirdSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        APP=$(echo $HOME/.nix-profile/Applications/Betterbird.app)

        if [ -d "$APP" ]; then
          /usr/bin/xattr -r -d com.apple.quarantine "$APP" 2>/dev/null || true

          ${lib.optionalString cfg.defaultMailClient ''
            ${pkgs.duti}/bin/duti -s ${bundleId} mailto
          ''}
          ${lib.optionalString cfg.defaultCalendarClient ''
            ${pkgs.duti}/bin/duti -s ${bundleId} webcal
          ''}
        fi
      '';
    };
  };
}
