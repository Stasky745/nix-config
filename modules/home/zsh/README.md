# Zsh Configuration Modules

This directory contains modular zsh configuration files that are automatically imported by `default.nix`.

## Module Overview

### Core Configuration
- **[default.nix](default.nix)** - Main orchestrator that imports all other modules and sets base zsh configuration
- **[aliases.nix](aliases.nix)** - Public shell aliases (committed to git)
- **[aliases.private.nix](aliases.private.nix.template)** - Private work aliases (gitignored, use template to create)

### Environment
- **[env.nix](env.nix)** - Environment variables and PATH configuration
- **[history.nix](history.nix)** - Command history settings (size, deduplication, sharing)

### User Experience
- **[completion.nix](completion.nix)** - Tab completion behavior (case-insensitive, partial matching)
- **[options.nix](options.nix)** - Shell options (auto-cd, directory stack)
- **[keybindings.nix](keybindings.nix)** - Keyboard shortcuts (Option+Arrow for word navigation)

### Functions
- **[functions.nix](functions.nix)** - Custom shell functions:
  - `gp` - Git pull main/master branch
  - `gps` - Git pull and switch to branch (with stash)
  - `git-rm-br` - Remove all local branches except main/master
  - `k-oom` - Find OOM-killed Kubernetes pods

### Integrations
- **[integrations.nix](integrations.nix)** - Third-party tool integrations:
  - direnv - Automatic environment loading per directory
  - starship - Cross-shell prompt
  - mise - Runtime version manager (formerly rtx)

## Adding New Modules

Any `.nix` file added to this directory (except `default.nix`) will be automatically imported. No need to update the imports list!

## Private Aliases

1. Copy the template:
   ```bash
   cp aliases.private.nix.template aliases.private.nix
   ```

2. Edit with your work-specific aliases

3. The file is gitignored and will never be committed
