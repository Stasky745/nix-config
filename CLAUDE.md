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

1. Create `modules/apps/<name>.nix` (or `modules/apps/<name>/default.nix` if it needs extra files alongside it, e.g. a config or theme file — see `modules/apps/ghostty/` or `modules/apps/cmux/`)
2. Add it to `modules/apps/default.nix` imports
3. Enable in the host's `config.nix`

This decision procedure is for **GUI apps only** (anything that installs a windowed `.app` bundle). CLI/TUI tools always install via a plain nixpkgs package in `home.packages` (see `sofka.nix`, `tart.nix`, `modules/apps/claude.nix`'s `code` option) — none of the Spotlight/packaging-lag reasoning below applies to them.

For a GUI app, check whether a Homebrew cask and/or a nixpkgs package exists:
- Only one of the two exists → use that one.
- **Both exist** → compare actual packaged versions against upstream's latest release (`brew info --cask <name>` vs `pkgs.<name>.version` vs the project's own release page/changelog) and pick whichever is more current. If both already match upstream's latest, prefer whichever was updated/bumped more recently (cask bump commit date vs. nixpkgs derivation's `lastModified`), if that's easy to determine. If neither is decidable, default to Homebrew.
- **Neither exists** → a custom `pkgs.stdenv.mkDerivation` fetching a `.dmg`/`.zip` directly is possible but discouraged — it makes you responsible for manually tracking upstream releases and bumping `version`/hash yourself (this repo used to do this for Betterbird; removed since it was never automated and went stale).

Concrete example from this repo: `cmux` was originally installed via `pkgs.cmux` (nixpkgs), but nixpkgs was pinned to `0.64.10` while the Homebrew cask tracked upstream's actual latest release (`0.64.22`, `auto_updates`) — so it was switched to `homebrew.casks = [ "cmux" ];` (see `modules/apps/cmux/default.nix`). `ghostty`, `vscode`, `brave`, `onepassword`, and Claude desktop are all cask-only (no competing nixpkgs package to compare against).

However installed, GUI apps land in `~/Applications/Home Manager Apps/` (nixpkgs route) or `/Applications` (Homebrew route) and are Spotlight/Launchpad-searchable either way — nixpkgs-installed ones via the global `copyApps` setting (see Known workarounds), Homebrew ones natively. No per-module symlinking code needed in either case.

`modules/apps/cmux/config` and `modules/apps/cmux/themes/mytheme` are intentional byte-for-byte duplicates of `modules/apps/ghostty/config`/`themes/mytheme` — cmux reads terminal appearance directly from `~/.config/ghostty/config` (it's built on `libghostty`), and cmux is meant to work standalone even on a host without the ghostty module enabled. To avoid two modules fighting over the same `xdg.configFile` path when both are enabled on one host, `modules/apps/cmux/default.nix` only writes that path when `my.apps.ghostty.enable` is false. If you edit the Ghostty config/theme, mirror the change into `modules/apps/cmux/` too (or vice versa) — they're not derived from each other.

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

- `home.file."Library/Fonts/.home-manager-fonts-version".enable = false` (set per-host) — works around a home-manager Darwin bug.

`hosts/darwin.nix` sets `targets.darwin.copyApps.enable = true` (and disables `linkApps`) globally, so any `.app` bundle in a module's `home.packages` is automatically copied into `~/Applications/Home Manager Apps/` and is Spotlight/Launchpad-searchable — no manual symlinking needed in app modules. (The old `pathsToLink` string-vs-list bug, https://github.com/nix-community/home-manager/issues/8163, is fixed upstream as of the home-manager version this repo pins.) `copyApps` needs macOS's "App Management" privacy permission to write into `~/Applications` — the first `task build` after enabling it (or on a fresh machine) will prompt for that permission interactively; it fails clearly (not silently) if run over SSH without Full Disk Access.

## Nix daemon settings — `nix.enable = false`

`hosts/darwin.nix` sets `nix.enable = false` because Determinate Nix (not nix-darwin) owns `/etc/nix/nix.conf` on these machines. This means **nix-darwin's `nix.settings.*` is a silent no-op** — its entire nix.conf-writing module is gated behind `mkIf cfg.enable` upstream. Don't add daemon-level settings (`max-jobs`, `cores`, substituters meant for the daemon, etc.) via `nix.settings` expecting them to take effect; they won't be written anywhere and will look configured while doing nothing.

Instead, pass such flags directly on the CLI in `Taskfile.yaml` (see `--max-jobs 4` on the `nix build`/`darwin-rebuild switch` commands, added to cap parallel-build memory use on-hardware with limited RAM).

`documentation.enable = false` and `manual.manpages/html/json.enable = false` (home-manager, via `home-manager.sharedModules`) are also set in `hosts/darwin.nix` — disabled because generating the full nix-darwin/home-manager options reference includes the private `mailerlite` module tree, which can never be served from a binary cache, so it was being rebuilt from scratch (multi-GB RAM, slow) on every single `task build`. If a future agent sees a switch using excessive memory/time, check these two things first before assuming it's a new problem.

## home-manager version pin

Unlike `nixpkgs` (tracks `nixpkgs-unstable`) and `nix-darwin` (tracks `master`), `home-manager` in `flake.nix` is pinned to a specific **stable release branch** (e.g. `release-26.05`), not a rolling branch. `task update` / `nix flake update` only pulls new commits *within* that branch — it will never move you to a newer release cycle. To upgrade home-manager:

1. Check available branches: `git ls-remote --heads https://github.com/nix-community/home-manager | grep release-`
2. Bump the branch name in `flake.nix`'s `home-manager.url`
3. `nix flake update home-manager`
4. `task build-check` and fix any option renames/removals (check `nix flake check` and build output for `mkRenamedOptionModule`/`mkRemovedOptionModule` warnings or errors)

If this pin is more than one or two release cycles behind current, treat that as a real signal to upgrade, not just cosmetic staleness — new home-manager features (like `targets.darwin.copyApps` above) only land on newer branches.

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
