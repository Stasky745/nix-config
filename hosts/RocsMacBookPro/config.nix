{ username, system, mailerlite, pkgs, ... }:
{
  # ---- MailerLite darwin-level config --------------------------------------
  mailerlite.team = "sre";

  # ---- Module enable flags -------------------------------------------------
  my.apps.tart.enable    = true;
  my.apps.sofka.enable   = true;
  my.base.zsh.enable     = true;

  # ---- Home-manager --------------------------------------------------------
  home-manager.users.${username} = { pkgs, ... }: {
    imports = [ mailerlite.modules.home-manager.defaults ];

    home.stateVersion              = "25.05";
    home.enableNixpkgsReleaseCheck = false;

    # Workaround: home-manager passes string instead of list to pathsToLink
    # https://github.com/nix-community/home-manager/issues/8163
    targets.darwin.linkApps.enable                                = false;
    home.file."Library/Fonts/.home-manager-fonts-version".enable = false;

    mailerlite = {
      team = "sre";
      ssh = {
        username          = "roc";
        use1PasswordAgent = true;
        extraIncludes     = [ "~/.ssh/private_hosts" ];
        extraConfig       = ''
          Host *
            SetEnv TERM=xterm-256color
        '';
      };
    };

    home.packages = mailerlite.pkgs.${system}.sre;
  };
}
