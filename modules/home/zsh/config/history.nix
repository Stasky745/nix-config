{ config, lib, pkgs, ... }:

{
  programs.zsh.history = {
    # Maximum number of commands to keep in memory during a session
    size = 10000;

    # Maximum number of commands to save in the history file
    save = 10000;

    # Where to save the history file
    path = "${config.home.homeDirectory}/.zsh_history";

    # Don't save duplicate commands consecutively (e.g., "ls" then "ls" again)
    ignoreDups = true;

    # Don't save commands that start with a space (useful for sensitive commands)
    ignoreSpace = true;

    # Share command history between all open zsh sessions in real-time
    # When you run a command in one terminal, it's immediately available in others
    share = true;
  };
}
