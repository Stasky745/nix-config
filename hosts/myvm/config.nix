{ username, enabled, ... }:
{
  # ---- Homebrew ------------------------------------------------------------
  homebrew.enable = true;

  # ---- Module enable flags -------------------------------------------------
  my = {
    apps = {
      betterbird = enabled // { defaultMailClient = true; defaultCalendarClient = true; };
      brave      = enabled // { defaultBrowser = true; };
      claude = {
        desktop = enabled;
        code    = enabled;
      };
      ghostty     = enabled;
      vscode      = enabled;
      onepassword = enabled // {
        sshAgent = enabled // {
          vaults = [
            { vault = "HomeOps"; }
          ];
        };
      };

    };
    base = {
      git = enabled;
      ssh = enabled // {
        use1PasswordAgent      = true;
        globalOptions."SetEnv" = "TERM=xterm-256color";
      };
      zsh = enabled;
    };
  };

  # ---- Home-manager --------------------------------------------------------
  home-manager.users.${username} = { ... }: {
    home.stateVersion              = "25.05";
    home.enableNixpkgsReleaseCheck = false;

    # Workaround: home-manager passes string instead of list to pathsToLink
    # https://github.com/nix-community/home-manager/issues/8163
    targets.darwin.linkApps.enable                                = false;
    home.file."Library/Fonts/.home-manager-fonts-version".enable = false;
  };
}
