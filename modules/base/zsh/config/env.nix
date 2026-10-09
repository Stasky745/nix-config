{ config, lib, pkgs, ... }:

{
  # Session variables (available in all shells)
  # EDITOR/TERMINAL are set by whichever app module has defaultEditor/defaultTerminal enabled.
  home.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
  };

  # Session PATH additions (prepended in order listed)
  # Note: Nix will automatically handle PATH for packages installed via home.packages
  home.sessionPath = [
    "$HOME/go/bin"
    "$HOME/.local/bin"
    "$HOME/.npm-global/bin"
    "$HOME/.istioctl/bin"
    "/opt/homebrew/bin"
  ];

  # /etc/zprofile's path_helper runs after ~/.zshenv (where sessionPath above
  # lands) and re-sorts PATH, pushing /usr/bin ahead of nix-provided tools;
  # re-prepend nix profiles here, in ~/.zprofile, which runs after path_helper.
  # Needed so `python3` resolves to nix's (my.apps.python) instead of the
  # broken /usr/bin/python3 xcode-select shim.
  programs.zsh.profileExtra = ''
    path=($HOME/.nix-profile/bin /nix/var/nix/profiles/default/bin $path)
    typeset -U path
  '';
}
