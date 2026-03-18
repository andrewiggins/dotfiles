# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles repository optimized for GitHub Codespaces. Configures bash, git, vim, and the Starship prompt. No build system or tests — changes are validated by running `bootstrap.sh` in a fresh environment.

## Setup

Run `./bootstrap.sh` to install everything. The script:

- Pulls latest dotfiles from the `main` branch
- Installs Starship prompt to `~/.local/bin`
- Installs Volta (Node.js version manager)
- Copies config files and appends to `~/.bashrc`
- Detects GitHub Codespaces via `$CODESPACES` env var for conditional setup

The script is idempotent — it appends to `.bashrc` only if not already present and creates directories before writing to them.

## Architecture

- **bootstrap.sh** — Entry point. Handles all installation, file copying, and git alias configuration. Uses `set -e`. Codespaces-specific logic is gated behind `[ "$CODESPACES" == "true" ]`.
- **.bashrc** — Sets up Volta PATH and initializes Starship with a custom window title hook.
- **.gitconfig** — Git settings (`push.default=current`, `rerere.enabled`, `init.defaultBranch=main`) and 23 aliases. Git LFS filter is required.
- **.vimrc** — Editor config with language-specific indentation (Python/JS: 4 spaces, YAML/HTML/CSS: 2 spaces) and function key mappings (F2/F3: quickfix nav, F4: make, F5: run file).
- **.config/starship.toml** — Prompt config with detailed git status display (posh-git style) and Nerd Font symbols. Container and Ruby modules disabled for Codespaces compatibility.

## Key Patterns

- **Non-destructive deployment**: Files are copied/appended, not symlinked. No use of GNU stow.
- **Shell-native**: Depends only on bash, curl, and git. No package manager beyond what's installed by the script.
- Git aliases are configured in `bootstrap.sh` via `git config --global` commands, not solely in `.gitconfig`.
