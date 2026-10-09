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

`modules/apps/thurm/` (another Ghostty-based terminal, same author as `sofka`) uses the official `programs.thurm` home-manager module from the `thurm` flake input (`github:nklmilojevic/thurm`, tracking `main` — the module landed via PR #55, merged 2026-10-02). The module is imported globally via `hosts/darwin.nix`'s `home-manager.sharedModules`. `programs.thurm.package` defaults to `null` on macOS (the app bundles its own `thurm`/`thurmd`), so like before, the app itself is still manually installed — only config is nix-managed. Unlike cmux, thurm doesn't read Ghostty's config format — `my.apps.thurm`'s `settings.colors` attrset is a hand-translated copy of the same palette in `modules/apps/ghostty/themes/mytheme` (the module TOML-encodes whatever's set under `settings`; only non-default keys need to be specified, which is why this is much shorter than a full config file). Mirror color changes manually if you touch the Ghostty theme. `programs.thurm.settings` still only manages `~/.config/thurm/config.toml` as a read-only symlink — `thurm set`/in-app settings changes will still fail; make changes here and rebuild. The module does add one QoL win over a plain `xdg.configFile`: `reloadOnChange` (default `true`) runs `thurm reload` automatically on activation if the daemon's already running.

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

`Taskfile.yaml` must stay go-task (not switched to `just`/another runner): MailerLite's shared `ml-build`/`ml-update` commands (from `mailerlite.pkgs`, defined in `~/.config/mailerlite/nix-config/modules/home-manager/ml-build/`) hardcode `task -t ~/nix-config/Taskfile.yaml build`/`update` — they don't know this repo exists beyond that exact path. Changing the task runner here would silently break those commands.

## Known workarounds

- `home.file."Library/Fonts/.home-manager-fonts-version".enable = false` (set per-host) — works around a home-manager Darwin bug.

`hosts/darwin.nix` sets `targets.darwin.copyApps.enable = true` (and disables `linkApps`) globally, so any `.app` bundle in a module's `home.packages` is automatically copied into `~/Applications/Home Manager Apps/` and is Spotlight/Launchpad-searchable — no manual symlinking needed in app modules. (The old `pathsToLink` string-vs-list bug, https://github.com/nix-community/home-manager/issues/8163, is fixed upstream as of the home-manager version this repo pins.) `copyApps` needs macOS's "App Management" privacy permission to write into `~/Applications` — the first `task build` after enabling it (or on a fresh machine) will prompt for that permission interactively; it fails clearly (not silently) if run over SSH without Full Disk Access.

## Nix daemon settings — `nix.enable = false`

`hosts/darwin.nix` sets `nix.enable = false` because Determinate Nix (not nix-darwin) owns `/etc/nix/nix.conf` on these machines. This means **nix-darwin's `nix.settings.*` is a silent no-op** — its entire nix.conf-writing module is gated behind `mkIf cfg.enable` upstream. Don't add daemon-level settings (`max-jobs`, `cores`, substituters meant for the daemon, etc.) via `nix.settings` expecting them to take effect; they won't be written anywhere and will look configured while doing nothing.

Instead, pass such flags directly on the CLI in `Taskfile.yaml` (see `--max-jobs 4` on the `nix build`/`darwin-rebuild switch` commands, added to cap parallel-build memory use on-hardware with limited RAM).

This bit `nix.settings.substituters`/`trusted-public-keys` for `nkl-sofka.cachix.org` too — it sat in `hosts/darwin.nix` for a long time looking configured while `nix show-config` confirmed it was never actually registered, so `sofka` silently rebuilt from source (a multi-minute Rust compile) on every version bump instead of hitting the cache. Fixed the same way: `Taskfile.yaml`'s `SOFKA_CACHE` var passes `--extra-substituters`/`--extra-trusted-public-keys` on the CLI. One extra wrinkle specific to substituters (unlike `max-jobs`): `trusted-users = root` only, so an *unprivileged* `nix build` (like `build-check`) still can't use an untrusted substituter via CLI flags — Nix just warns `ignoring untrusted substituter` and builds from source anyway. Only `switch-config` (already `sudo`, i.e. root, which is trusted) actually benefits. `build-check` is deliberately left unprivileged (no sudo just to sanity-check a build), so it will keep rebuilding `sofka` from source on version bumps — that's expected, not a bug to re-chase.

`modules/apps/sofka.nix` consumes `inputs.sofka.packages.${system}.sofka` directly rather than `pkgs.sofka` via `inputs.sofka.overlays.default` (no longer applied in `hosts/darwin.nix`). The overlay rebuilds `sofka` against *our* `nixpkgs` (`nixpkgs-unstable`, continuously updated) — a derivation hash nkl-sofka.cachix.org never has, since sofka's own CI publishes against sofka's pinned `nixpkgs` (`nixos-26.05`) instead. Consuming the package straight from the `sofka` flake's own output uses its locked `nixpkgs`, which actually matches what's cached. For the same reason, the `sofka` input itself does *not* set `inputs.nixpkgs.follows = "nixpkgs"` — don't add it back, it would force the mismatch again. If you ever re-lock this input, use `nix flake update sofka` (not `nix flake check`'s incremental add-input path) — the latter re-resolves sofka's floating `nixos-26.05` ref to its current branch HEAD instead of inheriting sofka's own committed lock, landing on a revision that isn't cached either.

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
