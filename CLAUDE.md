# CLAUDE.md

## Overview

Cross-platform dotfiles repository deployed via a plain shell installer (`install.sh`) and PowerShell installer (`install.ps1`). Files in `home/` are symlinked into `$HOME`; per-OS and per-context differences are handled by runtime detection in shell, not by a templating engine.

Supports Linux, macOS, Windows, GitHub Codespaces, and WSL from a single set of source files.

## Setup

```sh
git clone https://github.com/andrewiggins/dotfiles.git ~/dotfiles
~/dotfiles/install.sh        # or install.ps1 on Windows
```

For Codespaces, `install.sh` is auto-discovered and runs without prompts. Codespaces is detected via the `$CODESPACES` env var.

## Architecture

```
dotfiles/
├── install.sh                 # Unix/macOS/WSL/Codespaces entry point
├── install.ps1                # Windows entry point
├── home/                      # Symlinked into $HOME
│   ├── .bashrc
│   ├── .zshrc                 # macOS only (skipped on other platforms)
│   ├── .zprofile              # macOS only
│   ├── .vimrc
│   ├── .editorconfig
│   └── .config/starship.toml
├── scripts/
│   ├── configure-git.sh       # `git config --global` calls (Unix)
│   ├── configure-git.ps1      # `git config --global` calls (Windows)
│   ├── install-packages-codespaces.sh
│   ├── install-packages-macos.sh
│   ├── install-packages-linux.sh
│   ├── install-packages-windows.ps1
│   └── configure-macos.sh     # macOS system defaults (Finder, Dock, etc.)
├── tests/
│   └── dry-run.sh             # Integration test against a temp HOME
└── docs/
    ├── RESEARCH.md            # Background research from the chezmoi era
    └── MACHINE_TYPES.md       # Historical work/personal split + how to revive
```

## Key Patterns

- **Runtime detection, not templating**: `install.sh` reads `uname -s`, `$CODESPACES`, and `/proc/version` (for WSL) and passes the results as env vars to downstream scripts. There is no template engine in the loop.
- **Idempotent git config**: `scripts/configure-git.sh` is a list of `git config --global …` calls. Re-running rewrites identical values; individual lines can be commented out per machine. Modeled on the older `andrewiggins/setup` repo's pattern.
- **`~/.extra` escape hatch**: Both `.bashrc` and `.zshrc` source `~/.extra` if it exists, for private or machine-specific config not tracked in git.
- **Symlinks, not copies**: Edits to files in `~/.bashrc` etc. flow back to the repo. On Windows this requires Developer Mode.
- **`SKIP_PACKAGES=1`** is honored by every package install script, so CI and test runs can exercise the full installer without actually invoking `brew`/`apt`/`winget`.
- **`DRY_RUN=1`** in `install.sh` previews actions without touching the filesystem.
- **`HOME=…`** can be set to redirect both symlinking and `git config --global` into a throwaway directory — `tests/dry-run.sh` uses this for full isolation.

## Validation

- CI runs on every push, every PR, and weekly (Monday 9 AM UTC) on `ubuntu-latest` and `macos-latest`. There is **no Windows CI** — `install.ps1` and `scripts/*-windows.ps1` must be tested manually.
- `bash tests/dry-run.sh` — full integration test (dry-run + real run with `SKIP_PACKAGES=1` against a temp dir + idempotency check). Run by CI on ubuntu and macos.
- `shellcheck install.sh scripts/*.sh tests/*.sh` — lint all shell scripts. Also run by CI.
- `DRY_RUN=1 ./install.sh` — preview what would change on the current machine.
- `bash -x install.sh` — debug a real run by tracing every command.

## Related Repos

- **`andrewiggins/setup`** — Older setup scripts repo; `configure-git.sh` pattern originated there. Available as an additional working directory.
