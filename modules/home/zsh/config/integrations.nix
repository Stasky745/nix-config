{ config, lib, pkgs, ... }:

{
  # Enable direnv - loads environment variables from .envrc files
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;  # Better Nix integration for direnv
  };

  # Enable starship - cross-shell prompt
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    # You can add starship configuration here if needed:
    # settings = {
    #   add_newline = false;
    #   character = {
    #     success_symbol = "[➜](bold green)";
    #     error_symbol = "[➜](bold red)";
    #   };
    # };
  };

  # mise - runtime version manager (formerly rtx)
  # Note: mise doesn't have a home-manager module yet, so we use manual integration
  programs.zsh.initContent = ''
    eval "$(${pkgs.mise}/bin/mise activate zsh)"
  '';

  # Note: The plugins from zsh.plugins (zsh-autosuggestions and zsh-syntax-highlighting)
  # are already handled natively by home-manager in the main flake.nix:
  # - programs.zsh.autosuggestion.enable = true
  # - programs.zsh.syntaxHighlighting.enable = true
}
