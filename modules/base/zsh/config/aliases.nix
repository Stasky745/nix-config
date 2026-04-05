{ config, lib, pkgs, ... }:

{
  programs.zsh.shellAliases = {
    # Public aliases - safe to commit
    # macOS ls with color support
    ls = "ls --color=auto";

    # Editor
    vi = "nvim";

    # Kubernetes shortcuts
    k = "kubectl";
    k9s = "k9s --logoless";

    myvm = "tart run --net-bridged en0 --dir=repos:~/repos/stasky myvm";
  };
}
