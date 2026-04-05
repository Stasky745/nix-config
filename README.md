# Nix Configuration

Personal Nix configuration for macOS using nix-darwin and home-manager.

## Structure

```
nix-config/
├── flake.nix                        # Inputs and host registrations
├── Taskfile.yaml                    # Build commands
├── hosts/
│   ├── darwin.nix                   # Shared defaults for all darwin hosts
│   ├── RocsMacBookPro/              # Work MacBook
│   │   ├── system.nix               # Host identity — darwinSystem call
│   │   ├── imports.nix              # Module categories + work imports
│   │   └── config.nix               # Enable flags and host configuration
│   └── vm/                          # macOS VM
│       ├── system.nix
│       ├── imports.nix
│       └── config.nix
└── modules/
    ├── apps/                        # Application modules (my.apps.*)
    │   └── tart.nix
    └── base/                        # Core user tools (my.base.*)
        └── zsh/                     # Zsh shell configuration
```

## How it works

### Hosts

Each host lives in `hosts/<hostname>/` and consists of three files:

- **`system.nix`** — the entry point. Defines `username` and `system` (architecture), then calls `nix-darwin.lib.darwinSystem`. Not meant to be edited often.
- **`imports.nix`** — declares which module categories this host loads, using `with modules; [ apps base ]`. Also imports any external modules (e.g. work tooling).
- **`config.nix`** — where you spend most of your time. Enables modules with `my.*` flags, sets package lists, configures tools.

All darwin hosts automatically inherit `hosts/darwin.nix`, which sets shared defaults: nixpkgs config, overlays, Determinate Nix flags, home-manager framework settings, and user account setup.

### Modules

Modules live under `modules/<category>/` and are auto-discovered from the `modules/` directory — adding a new category folder makes it available as `modules.<name>` in every host's `imports.nix` automatically.

Every module is **opt-in**: nothing runs unless explicitly enabled in a host's `config.nix`. Each module declares a `my.<category>.<name>.enable` option:

```nix
# Enable in config.nix
my.apps.tart.enable   = true;
my.base.zsh.enable    = true;
```

Current module categories:

| Category | Option prefix | Contents |
|----------|--------------|----------|
| `apps/`  | `my.apps.*`  | Applications (tart, …) |
| `base/`  | `my.base.*`  | Core tools (zsh, …) |

### Adding a new module

1. Create `modules/<category>/<name>.nix`:

```nix
{ config, lib, pkgs, username, ... }:
let cfg = config.my.<category>.<name>; in
{
  options.my.<category>.<name>.enable = lib.mkEnableOption "<description>";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = { ... }: {
      # home-manager config here
    };
  };
}
```

2. Add it to `modules/<category>/default.nix`:

```nix
imports = [ ./<name>.nix ];
```

3. Enable it in a host's `config.nix`:

```nix
my.<category>.<name>.enable = true;
```

### Adding a new host

1. Create `hosts/<hostname>/system.nix`:

```nix
{ inputs, modules }:
let
  username = "<user>";
  system   = "aarch64-darwin";
in
inputs.nix-darwin.lib.darwinSystem {
  inherit system;
  specialArgs = { inherit inputs modules username system; inherit (inputs) mailerlite; };
  modules = [
    inputs.home-manager.darwinModules.home-manager
    ../darwin.nix
    ./imports.nix
    ./config.nix
  ];
}
```

2. Create `hosts/<hostname>/imports.nix` — list the module categories the host needs.

3. Create `hosts/<hostname>/config.nix` — enable modules and add configuration.

4. Register in `flake.nix`:

```nix
darwinConfigurations.<hostname> = import ./hosts/<hostname>/system.nix { inherit inputs modules; };
```

## Tasks

```bash
task build          # Update mailerlite input and apply config to current host
task update         # Update all flake inputs
task update-build   # Update all inputs and rebuild
task gc             # Garbage collect the Nix store
```

`task build` detects the current machine by its computer name (`scutil --get ComputerName`) and matches it against the host directories. If no match is found, it prompts you to select from the available hosts.

## Requirements

- **Nix**: Installed via Determinate Systems installer
- **go-task**: Used as task runner (`brew install go-task`)
