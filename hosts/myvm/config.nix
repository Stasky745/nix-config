{ username, enabled, ... }:
{
  # ---- Homebrew ------------------------------------------------------------
  homebrew.enable = true;

  # ---- Module enable flags -------------------------------------------------
  my = {
    apps = {
      claude = {
        desktop = enabled;
        code    = enabled;
      };
      ghostty     = enabled;
      onepassword = enabled // {
        sshAgent = enabled // {
          vaults = [
            { vault = "HomeOps"; }
          ];
        };
      };

    };
    base = {
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
