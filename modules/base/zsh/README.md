# ZSH Module

A modular Nix configuration for ZSH with sensible defaults, custom functions, and tool integrations.

## Features

### Core Configuration
- Auto-completion and syntax highlighting
- Smart autosuggestions with history-based completion
- Shared command history across all sessions (10,000 entries)
- Interactive comments support
- Steady bar cursor style

### Directory Navigation
- `auto_cd` - Type directory names to navigate without `cd`
- `auto_pushd` - Automatic directory stack management
- Enhanced directory history with `cd -`, `cd -2`, etc.

### Tool Integrations
- **Starship** - Modern cross-shell prompt
- **direnv** - Automatic environment variable loading from `.envrc` files
- **mise** - Runtime version manager (replaces asdf/rtx)

### Aliases
- `ls` - Colorized ls output
- `vi` - Launches nvim
- `k` - kubectl shortcut
- `k9s` - Launches k9s without logo

### Custom Functions

**Git Workflows**
- `gp` - Switch to main/master branch and pull latest changes
- `gps <branch>` - Pull main, switch/create branch, merge main (with auto-stash)
- `git-rm-br` - Clean up local branches (keeps main/master/current)

**Kubernetes Utilities**
- `k-oom [limit]` - Find and display OOM-killed pods with detailed info

### Keybindings
- **Option+Left/Right** - Jump between words (VSCode & terminal compatible)
- Works in both standard terminals and VSCode integrated terminal

### Environment
- `EDITOR` - Set to `code -w` (VSCode)
- `XDG_CONFIG_HOME` - Set to `$HOME/.config`
- **PATH additions** - Go, local binaries, npm global, istioctl, Homebrew

## How It Works

The module uses automatic discovery to keep configuration organized:

- [default.nix](default.nix) - Main entry point that automatically imports all `*.nix` files from the `config/` directory
- [config/functions.nix](config/functions.nix) - Scans `config/functions.d/` and automatically loads all `*.sh` files as shell functions
- Individual config files ([aliases.nix](config/aliases.nix), [history.nix](config/history.nix), etc.) - Each handles a specific aspect of the shell configuration

## Adding Custom Functions

Simply drop new `.sh` files into [config/functions.d/](config/functions.d/) - they'll be automatically discovered and loaded on shell initialization.

## Customization

Each config file is self-contained and can be modified independently without touching the main module structure.
