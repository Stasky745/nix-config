{ config, lib, ... }:

{
  programs.zsh.initContent = ''
    # VSCode terminal sequences
    bindkey '^[[1;3C' forward-word      # Option+Right in VSCode
    bindkey '^[[1;3D' backward-word     # Option+Left in VSCode

    # Standard terminal sequences
    bindkey '^[b' backward-word         # Option+Left in normal terminal
    bindkey '^[f' forward-word          # Option+Right in normal terminal
  '';
}
