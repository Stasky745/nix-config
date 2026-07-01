{ lib, config, pkgs, username, ... }:

let
  cfg = config.my.apps.sofka;
in
{
  options.my.apps.sofka.enable = lib.mkEnableOption "sofka Kubernetes TUI";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = { ... }: {
      home.packages = [ pkgs.sofka ];

      # Overrides on top of catppuccin-mocha to match the ghostty terminal
      # palette (modules/apps/ghostty/themes/mytheme), which is what k9s
      # (default skin) and zsh render through in this terminal already.
      xdg.configFile."sofka/config.toml".text = ''
        [skin]
        name = "catppuccin-mocha"

        [skin.colors]
        base = "#14191e"
        mantle = "#14191e"
        crust = "#14191e"
        text = "#dbdbdb"
        red = "#b43c29"
        green = "#00c200"
        yellow = "#c7c400"
        blue = "#2743c7"
        mauve = "#bf3fbd"
        teal = "#00c5c7"
        sapphire = "#00c5c7"
      '';
    };
  };
}
