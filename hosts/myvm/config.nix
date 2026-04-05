{ username, ... }:
{
  # ---- Module enable flags -------------------------------------------------
  my.base.zsh.enable = true;

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
