# nix-config

Declarative macOS configuration using nix-darwin + home-manager. Everything is opt-in per host.

## Structure

```
hosts/
  darwin.nix          # Shared defaults for all hosts
  <hostname>/
    system.nix        # Entry point — calls nix-darwin.lib.darwinSystem
    imports.nix       # Which module categories to load
    config.nix        # Which modules to enable and their options

modules/
  apps/               # my.apps.* namespace — GUI apps
  base/               # my.base.* namespace — shell, git, ssh, etc.

stubs/
  mailerlite/         # Empty flake stub for machines without MailerLite config

Taskfile.yaml         # go-task: build, update, gc
flake.nix             # Inputs + auto-discovers modules/ directories
```

## How the flake works

`flake.nix` auto-discovers module categories from `./modules/*` using `builtins.readDir`. Each subdirectory becomes available as `modules.<name>` in a host's `imports.nix`. Adding a new folder to `modules/` makes it available automatically — no manual registration in `flake.nix` needed.

The `mailerlite` input points to an external path only present on certain machines. On machines where it doesn't exist, `Taskfile.yaml` automatically injects `--override-input mailerlite path:./stubs/mailerlite`.

## Module pattern

Every module follows the same shape:

```nix
{ lib, config, pkgs, username, ... }:
let cfg = config.my.<category>.<name>; in
{
  options.my.<category>.<name> = {
    enable = lib.mkEnableOption "description";
    dock   = lib.mkEnableOption "pin to dock" // { default = true; };
    # other options
  };
  config = lib.mkIf cfg.enable {
    # only applied when enabled
  };
}
```

Nothing runs unless explicitly enabled in a host's `config.nix`.

## Key helpers

`enabled` and `disabled` are injected via `_module.args` and `home-manager.extraSpecialArgs` from `hosts/darwin.nix`:

```nix
enabled  = { enable = true; };
disabled = { enable = false; };
```

Use in `config.nix`:

```nix
my.apps.vscode = enabled;
my.apps.brave  = enabled // { defaultBrowser = true; };
```

## Adding a new app module

1. Create `modules/apps/<name>.nix`
2. Add it to `modules/apps/default.nix` imports
3. Enable in the host's `config.nix`

## Adding a new host

1. Create `hosts/<hostname>/system.nix` (copy from an existing host)
2. Create `hosts/<hostname>/imports.nix`
3. Create `hosts/<hostname>/config.nix`
4. Register in `flake.nix` outputs

## Build

```bash
task build        # Build and switch to new config
task update       # Update flake.lock + pinned app versions
task update-build # Update then build
task gc           # Nix garbage collect
```

Hostname is auto-detected via `scutil --get ComputerName`.

## Known workarounds

Some hosts may have these flags in their home-manager block due to home-manager Darwin bugs:

- `targets.darwin.linkApps.enable = false` — home-manager passes a string instead of a list to `pathsToLink` (https://github.com/nix-community/home-manager/issues/8163). When this is disabled, app modules that install via `home.packages` must manually symlink to `~/Applications/` in `home.activation`.
- `home.file."Library/Fonts/.home-manager-fonts-version".enable = false` — related Darwin bug.

## Machine-specific identity

Git name/email are kept out of this repo. Each machine needs `~/.gitconfig.local`:

```ini
[user]
  name  = Your Name
  email = you@example.com
```

The git module prints a reminder on activation if this file is missing.

## SSH config

`modules/base/ssh.nix` writes `~/.ssh/config` directly via `home.file` (not `programs.ssh`) to avoid home-manager generating a duplicate `Host *` block. Do not set `IdentitiesOnly yes` globally — it blocks agent keys unless paired with an explicit `IdentityFile`.
