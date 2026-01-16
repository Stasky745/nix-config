{ config, lib, pkgs, ... }:

{
  programs.zsh.initContent = ''
    # Directory navigation improvements

    # auto_cd: Just type a directory name to cd into it
    # Example: Instead of "cd ~/Documents", just type "~/Documents"
    setopt auto_cd

    # auto_pushd: Automatically save directories to a stack when you cd
    # You can then use "cd -" to go back, or "cd -2" to go back 2 directories
    setopt auto_pushd

    # pushd_ignore_dups: Don't add duplicate directories to the stack
    # Keeps your directory history cleaner
    setopt pushd_ignore_dups

    # pushd_minus: Swap the meaning of + and - with pushd
    # Makes "cd -1" go to the previous directory (more intuitive)
    setopt pushd_minus
  '';
}
