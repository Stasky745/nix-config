{ config, lib, pkgs, ... }:

{
  # Session variables (available in all shells)
  home.sessionVariables = {
    EDITOR = "zed --wait";
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
    "/Library/Frameworks/Python.framework/Versions/3.11/bin" # Pip
  ];
}
