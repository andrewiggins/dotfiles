# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Cross-platform dotfiles repository managed with [chezmoi](https://www.chezmoi.io/). Supports Linux, macOS, Windows, and GitHub Codespaces from a single set of source files using Go templates for per-OS/per-context differences.

## Setup

Run `chezmoi init --apply andrewiggins` to install everything. For Codespaces, `install.sh` is detected automatically and runs chezmoi non-interactively.

chezmoi prompts for two data values on first run:
- `email` — git commit email (personal or work)
- `machine_type` — `personal`, `work`, or `codespaces` (controls package installation scope)

## Architecture

This repo **is** the chezmoi source directory. chezmoi copies files to the home directory, applying templates (`.tmpl` files) and respecting `.chezmoiignore` for OS-conditional exclusion.

### Key files

- **`.chezmoi.toml.tmpl`** — chezmoi config template; prompts for email and machine type
- **`.chezmoiignore`** — excludes platform-specific files (e.g., `.zshrc` on non-macOS, `Documents/` on non-Windows)
- **`private_dot_gitconfig.tmpl`** — unified git config with templated email, delta pager (skipped in Codespaces), WSL credential helper detection, all aliases
- **`dot_bashrc.tmpl`** — bash config (Linux/WSL): Volta PATH, Starship init, window title hook
- **`dot_zshrc.tmpl`** — zsh config (macOS only): Starship init, window title hook, `codei` alias
- **`dot_zprofile.tmpl`** — zsh profile (macOS only): Homebrew Python PATH, Volta
- **`Documents/PowerShell/Microsoft.PowerShell_profile.ps1`** — PowerShell profile (Windows only): Starship init
- **`dot_vimrc`** — vim config: persistent undo, scrolloff, incremental search
- **`dot_editorconfig`** — EditorConfig: tabs by default, 2-space for JSON/YAML/rc files
- **`dot_config/starship.toml`** — Starship prompt config with Nerd Font symbols and posh-git style git status
- **`run_once_before_install-packages.sh.tmpl`** — Linux/macOS package installation (lightweight for Codespaces, full for local)
- **`run_once_before_install-packages.ps1.tmpl`** — Windows package installation via winget/cargo
- **`run_once_after_configure-macos.sh.tmpl`** — macOS system defaults (Finder, Dock, keyboard, etc.)
- **`install.sh`** — Codespaces/Dev Container bootstrap entry point

### chezmoi naming conventions

- `dot_` prefix → `.` in target (e.g., `dot_vimrc` → `.vimrc`)
- `private_` prefix → file permissions 0600
- `.tmpl` suffix → Go template, rendered with chezmoi data
- `run_once_before_` / `run_once_after_` → idempotent scripts that run once (tracked by content hash)

## Key Patterns

- **Templated differences**: OS/context differences are handled via `{{ if }}` blocks in `.tmpl` files, not separate files per platform
- **`machine_type` gating**: Codespaces gets lightweight installs (starship + volta only); local machines get full package sets
- **`~/.extra` pattern**: Both `.bashrc` and `.zshrc` source `~/.extra` if it exists, for private/machine-specific config not tracked in git
- **Non-destructive**: chezmoi copies files (not symlinks), matching the previous approach

## Validation

- `chezmoi diff` — preview what would change
- `chezmoi apply -v` — apply with verbose output
- `chezmoi doctor` — check chezmoi health
- Test in Codespaces by setting this repo as your dotfiles repository
