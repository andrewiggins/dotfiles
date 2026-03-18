# dotfiles

Cross-platform dotfiles managed with [chezmoi](https://www.chezmoi.io/). Works on Linux, macOS, Windows, and GitHub Codespaces.

## What's configured

- **Git** — aliases, delta pager (side-by-side diffs), VS Code merge tool, LFS, credential helpers
- **Shell** — bash (Linux/WSL), zsh (macOS), PowerShell (Windows) with Starship prompt
- **Vim** — persistent undo, incremental search, sensible defaults
- **EditorConfig** — consistent formatting across editors
- **Starship** — Nerd Font symbols, posh-git style git status
- **Packages** — platform-specific package installation (apt, Homebrew, winget, cargo)

## Install

### GitHub Codespaces

Set this repo as your [dotfiles repository](https://docs.github.com/en/codespaces/customizing-your-codespace/personalizing-github-codespaces-for-your-account#dotfiles) in GitHub settings. `install.sh` runs automatically.

### macOS

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply andrewiggins
```

### Linux / WSL

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply andrewiggins
```

### Windows

```powershell
winget install twpayne.chezmoi
chezmoi init --apply andrewiggins
```

## Customization

On first run, chezmoi prompts for:
- **Email** — sets `user.email` in git config
- **Machine type** — `personal`, `work`, or `codespaces` — controls which packages are installed

For private/machine-specific shell config, create `~/.extra` — it's sourced by both `.bashrc` and `.zshrc` if present.

## Updating

```sh
chezmoi update
```

## License

[MIT](LICENSE)
