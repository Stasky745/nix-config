{ lib, config, pkgs, username, ... }:

let
  cfg      = config.my.apps.betterbird;
  bundleId = "eu.betterbird.Betterbird";

  package = pkgs.stdenv.mkDerivation rec {
    pname   = "betterbird";
    version = "140.11.0esr-bb23";

    src = pkgs.fetchurl {
      url    = "https://www.betterbird.eu/downloads/MacDiskImage/betterbird-${version}.en-US.mac.dmg";
      sha256 = "sha256-1qzfJWd513U5uX1I+Z5dq8yTGoekJQsz1eGsCgUAP9M=";
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
    defaultMailClient     = lib.mkEnableOption "set as default mail client";
    defaultCalendarClient = lib.mkEnableOption "set as default calendar client";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = { lib, ... }: {
      home.packages = [ package ];

      home.activation.betterbirdSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        SRC="${package}/Applications/Betterbird.app"
        DEST="$HOME/Applications/Betterbird.app"

        mkdir -p "$HOME/Applications"
        rm -rf "$DEST"
        ln -sf "$SRC" "$DEST"
        /usr/bin/xattr -r -d com.apple.quarantine "$SRC" 2>/dev/null || true

        ${lib.optionalString cfg.defaultMailClient ''
          ${pkgs.duti}/bin/duti -s ${bundleId} mailto  2>/dev/null || true
        ''}
        ${lib.optionalString cfg.defaultCalendarClient ''
          ${pkgs.duti}/bin/duti -s ${bundleId} webcal  2>/dev/null || true
        ''}
      '';
    };
  };
}
