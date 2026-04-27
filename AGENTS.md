# Repository Guidelines

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
│   ├── configure-git.sh       # `git config --global` calls (all platforms)
│   ├── configure-claude.sh    # Claude Code settings.json setup (all platforms)
│   ├── install-ai-agents.sh   # Claude/Codex/pi-agent install (Unix/macOS/WSL/Codespaces)
│   ├── install-ai-agents.ps1  # Claude/Codex/pi-agent install (Windows)
│   ├── install-packages-codespaces.sh
│   ├── install-packages-macos.sh
│   ├── install-packages-linux.sh
│   ├── install-packages-windows.ps1
│   └── configure-macos.sh     # macOS system defaults (Finder, Dock, etc.)
├── tests/
│   ├── dry-run.sh             # Integration test against a temp HOME
│   ├── install-modes.sh       # Verifies native Linux / WSL / Codespaces detection
│   └── statusline.sh          # Verifies Claude Code statusline rendering
└── docs/
    ├── RESEARCH.md            # Background research from the chezmoi era
    └── MACHINE_TYPES.md       # Historical work/personal split + how to revive
```

`install.sh` is the Unix/macOS/WSL/Codespaces entry point; `install.ps1` handles native Windows. Source dotfiles live under `home/` and are symlinked into `$HOME` at install time. Shared setup logic lives in `scripts/`, with platform-specific installers such as `install-packages-linux.sh`, `install-packages-windows.ps1`, and the cross-platform AI-agent install scripts. Integration and regression checks live in `tests/`. Background notes belong in `docs/`.

## Key Patterns

- **Runtime detection, not templating**: `install.sh` reads `uname -s`, `$CODESPACES`, and WSL signals (`WSL_DISTRO_NAME`, `WSL_INTEROP`, `/proc/version`) and passes the results as env vars to downstream scripts. There is no template engine in the loop.
- **Idempotent git config**: `scripts/configure-git.sh` is a list of `git config --global …` calls. Re-running rewrites identical values; individual lines can be commented out per machine. Modeled on the older `andrewiggins/setup` repo's pattern.
- **Git Bash for shared config on Windows**: `install.ps1` calls shared bash scripts (`configure-git.sh`, `configure-claude.sh`) via Git Bash instead of maintaining duplicate PowerShell versions. Git Bash is found by resolving `bash.exe` relative to `git.exe`'s install directory to avoid accidentally using WSL's bash.
- **`~/.extra` escape hatch**: Both `.bashrc` and `.zshrc` source `~/.extra` if it exists, for private or machine-specific config not tracked in git.
- **Symlinks, not copies**: Edits to files in `~/.bashrc` etc. flow back to the repo. On Windows this requires Developer Mode.
- **`SKIP_PACKAGES=1`** is honored by every package install script, so CI and test runs can exercise the full installer without actually invoking `brew`/`apt`/`winget`.
- **`DRY_RUN=1`** in `install.sh` previews actions without touching the filesystem.
- **`HOME=…`** can be set to redirect both symlinking and `git config --global` into a throwaway directory — `tests/dry-run.sh` uses this for full isolation.

## Build, Test, and Development Commands

Use the installers directly; there is no separate build step.

- `bash tests/dry-run.sh`: CI-backed integration test using a temporary `HOME` (dry-run + real run with `SKIP_PACKAGES=1` + idempotency check). Run by CI on ubuntu and macos.
- `bash tests/statusline.sh`: verifies `home/.claude/statusline-command.sh`.
- `bash tests/install-modes.sh`: verifies native Linux / WSL / Codespaces detection in `install.sh`.
- `shellcheck install.sh scripts/*.sh tests/*.sh`: lint all shell scripts. Also run by CI.
- `DRY_RUN=1 ./install.sh`: preview symlink and config changes without modifying the machine.
- `bash -x install.sh`: trace installer execution when debugging.

CI runs on every push, every PR, and weekly (Monday 9 AM UTC) on `ubuntu-latest` and `macos-latest`. There is **no Windows CI** — `install.ps1` and `scripts/*-windows.ps1` must be tested manually.

## Coding Style & Naming Conventions

Shell scripts use Bash with `set -euo pipefail`, tabs in existing case/loop blocks, and small idempotent functions. Keep filenames descriptive and platform-specific: `install-packages-<platform>.sh` or `configure-<area>.sh`. PowerShell stays in `.ps1` files and should mirror the behavior of the shell installer rather than fork logic unnecessarily. Run `shellcheck` before opening a PR; this repo already carries a shared `.shellcheckrc`.

## Testing Guidelines

Prefer integration-style tests over mocks. Add new shell tests under `tests/` as executable `.sh` files with concise names like `feature-name.sh`. Validate install changes with `SKIP_PACKAGES=1` when possible to avoid external package managers. Windows changes require manual verification because CI does not run Windows jobs.

## Commit & Pull Request Guidelines

Recent history uses short, imperative commit subjects such as `Add Docker-based full install testing` and `Fix statusline path shortening on Windows`. Follow that pattern, keep subjects focused, and separate unrelated changes. PRs should explain the user-visible behavior change, list the commands you ran, and note platform coverage such as `macOS`, `Linux`, `Codespaces`, or `Windows manual test`. Screenshots are unnecessary unless a terminal rendering change would be hard to describe.

## Related Repos

- **`andrewiggins/setup`** — Older setup scripts repo; `configure-git.sh` pattern originated there. Available as an additional working directory.
