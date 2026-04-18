{ lib, config, pkgs, username, ... }:

let
  cfg = config.my.apps.vscode;
in
{
  options.my.apps.vscode = {
    enable = lib.mkEnableOption "Visual Studio Code";
    dock   = lib.mkEnableOption "pin to dock" // { default = true; };

    sopsAgeKeyFile = lib.mkOption {
      type        = lib.types.nullOr lib.types.str;
      default     = null;
      description = "Absolute path to the age key file for the SOPS extension";
    };

    pythonInterpreterPath = lib.mkOption {
      type        = lib.types.nullOr lib.types.str;
      default     = null;
      description = "Absolute path to the Python interpreter";
    };

    extraSettings = lib.mkOption {
      type    = lib.types.attrs;
      default = {};
      description = "Additional VS Code settings merged with the defaults";
    };
  };

  config = lib.mkIf cfg.enable {
    homebrew.casks = [ "visual-studio-code" ];

    system.defaults.dock.persistent-apps = lib.mkIf cfg.dock [ "/Applications/Visual Studio Code.app" ];

    home-manager.users.${username} = { pkgs, lib, ... }: let
      extensions = with pkgs.vscode-extensions; [
        # Nix
        bbenoist.nix

        # Go
        golang.go

        # GitHub
        github.copilot-chat
        github.github-vscode-theme
        github.vscode-github-actions

        # Python
        ms-python.python
        ms-python.debugpy
        ms-python.vscode-pylance

        # Azure / Docker
        ms-azuretools.vscode-docker
        ms-azuretools.vscode-containers

        # Kubernetes
        ms-kubernetes-tools.vscode-kubernetes-tools

        # Remote
        ms-vscode-remote.remote-containers

        # Red Hat
        redhat.vscode-yaml

        # HashiCorp
        hashicorp.terraform

        # Misc
        gruntfuggly.todo-tree
        yzhang.markdown-all-in-one
      ];
    in {
      home.activation.vscodeExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        extDir="$HOME/.vscode/extensions"
        $DRY_RUN_CMD mkdir -p "$extDir"
        ${lib.concatMapStrings (ext: ''
          for d in "${ext}/share/vscode/extensions"/*/; do
            [ -d "$d" ] || continue
            $DRY_RUN_CMD ln -sfn "$d" "$extDir/$(basename "$d")"
          done
        '') extensions}
      '';

      home.file."Library/Application Support/Code/User/settings.json".text =
        builtins.toJSON (
          {
            "workbench.colorTheme"   = "GitHub Dark Default";
            "window.title"           = "\${rootName}";

            "terminal.integrated.fontFamily" = "Firacode Nerd Font Mono";

            "editor.formatOnSave"    = true;
            "diffEditor.ignoreTrimWhitespace" = false;

            "github.gitProtocol"     = "ssh";

            "application.shellEnvironmentResolutionTimeout" = 30;

            "security.workspace.trust.untrustedFiles" = "open";

            "go.toolsManagement.autoUpdate" = true;

            "docker.extension.enableComposeLanguageServer" = false;

            "claudeCode.preferredLocation" = "panel";
            "claudeCode.selectedModel"     = "default";

            "chat.agent.enabled" = false;

            "yaml.schemas" = {
              "https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/refs/heads/main/helmrelease-helm-v2.json"      = "helm-release*.yaml";
              "https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/refs/heads/main/kustomization-kustomize-v1.json" = "kustomization*.yaml";
              "https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/refs/heads/main/gitrepository-source-v1.json"    = "gitrepository*.yaml";
              "https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/refs/heads/main/helmrepository-source-v1.json"   = "helmrepository*.yaml";
            };

            "[yaml]" = {
              "editor.insertSpaces"       = true;
              "editor.tabSize"            = 2;
              "editor.detectIndentation"  = false;
              "editor.autoIndent"         = "keep";
              "diffEditor.ignoreTrimWhitespace" = false;
              "editor.defaultColorDecorators"   = "never";
              "editor.quickSuggestions" = {
                "other"    = true;
                "comments" = false;
                "strings"  = true;
              };
            };

            "[dockercompose]" = {
              "editor.insertSpaces"     = true;
              "editor.tabSize"          = 2;
              "editor.autoIndent"       = "advanced";
              "editor.defaultFormatter" = "redhat.vscode-yaml";
              "editor.quickSuggestions" = {
                "other"    = true;
                "comments" = false;
                "strings"  = true;
              };
            };

            "[github-actions-workflow]" = {
              "editor.defaultFormatter" = "redhat.vscode-yaml";
            };

            "launch" = {
              "version" = "0.2.0";
              "configurations" = [
                {
                  "name"         = "Debug Main File";
                  "type"         = "go";
                  "request"      = "launch";
                  "mode"         = "debug";
                  "debugAdapter" = "dlv-dap";
                  "program"      = "\${workspaceFolder}/cmd/\${workspaceFolderBasename}";
                  "envFile"      = "\${workspaceFolder}/.env";
                }
              ];
              "compounds" = [];
            };
          }
          // lib.optionalAttrs (cfg.sopsAgeKeyFile != null) {
            "sops.defaults.ageKeyFile" = cfg.sopsAgeKeyFile;
          }
          // lib.optionalAttrs (cfg.pythonInterpreterPath != null) {
            "python.defaultInterpreterPath" = cfg.pythonInterpreterPath;
          }
          // cfg.extraSettings
        );
    };
  };
}
