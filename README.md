# dotfiles

Cross-platform dotfiles managed with a plain shell installer and symlinks. Works on Linux, macOS, Windows, and GitHub Codespaces.

## What's configured

- **Git** — aliases, delta pager (side-by-side diffs), VS Code merge tool, LFS, credential helpers
- **Shell** — bash (Linux/WSL), zsh (macOS), PowerShell (Windows) with Starship prompt
- **Vim** — persistent undo, incremental search, sensible defaults
- **EditorConfig** — consistent formatting across editors
- **Starship** — Nerd Font symbols, posh-git style git status
- **Packages** — platform-specific package installation (apt, Homebrew, winget, upstream release/install scripts)
- **Containers** — Podman on Linux, macOS, and Windows; skipped in GitHub Codespaces

## Install

### GitHub Codespaces

Set this repo as your [dotfiles repository](https://docs.github.com/en/codespaces/customizing-your-codespace/personalizing-github-codespaces-for-your-account#dotfiles) in GitHub settings. `install.sh` runs automatically and detects Codespaces via the `$CODESPACES` env var to do a lightweight setup (just Starship + Volta).

### Linux / macOS / WSL

```sh
git clone https://github.com/andrewiggins/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

On native Linux, the installer adds Podman via `apt`.

On WSL, the installer intentionally skips a local Podman daemon and expects you to install Podman on the Windows host instead.

### Windows

Requires Developer Mode (Settings → Privacy & Security → For developers) so symlinks can be created without elevation.

```powershell
git clone https://github.com/andrewiggins/dotfiles.git $HOME\dotfiles
& $HOME\dotfiles\install.ps1
```

The Windows installer installs Podman Desktop, but leaves Podman machine setup to a manual first run.

## How it works

`install.sh` (and `install.ps1` on Windows):

1. Detects environment (`uname -s`, `$CODESPACES`, WSL via `WSL_DISTRO_NAME` / `WSL_INTEROP` or `/proc/version`).
2. Symlinks every file under `home/` into `$HOME`, skipping macOS-only files (`.zshrc`, `.zprofile`) on other platforms.
3. Runs the appropriate `scripts/install-packages-*.sh` for the detected OS.
4. Runs `scripts/configure-git.sh`, which is just a list of `git config --global …` calls — idempotent and individually editable per-machine.

Podman behavior by platform:

- Linux: installs native rootless Podman packages.
- macOS: installs Podman with Homebrew.
- Windows: installs Podman Desktop.
- WSL: uses the Windows-host Podman machine instead of installing a second engine inside WSL.
- Codespaces: skips Podman entirely because the container runtime is already provided.

The whole thing is plain shell. To debug, run `bash -x install.sh`. To preview without changes, `DRY_RUN=1 ./install.sh`. To test against a throwaway home, `HOME=/tmp/test ./install.sh`.

## Customization

For private or machine-specific shell config, create `~/.extra` — it's sourced by both `.bashrc` and `.zshrc` if present. Not tracked in git.

To change git email per machine, either edit `scripts/configure-git.sh` directly or set `GIT_EMAIL=…` in your environment before running.

For the historical `personal` vs `work` machine_type distinction (and how to reintroduce it if needed), see [`docs/MACHINE_TYPES.md`](docs/MACHINE_TYPES.md).

## Updating

```sh
cd ~/dotfiles && git pull && ./install.sh
```

Re-running the installer is safe — symlinks are recreated and `git config` calls overwrite identical values.

## Verify Podman

After installation on Linux:

```sh
podman info
podman run --rm hello-world
```

On macOS or Windows, initialize and start Podman first, then verify:

```sh
podman machine init
podman machine start
podman info
podman run --rm hello-world
```

From WSL, use the Windows-host install after the Windows machine has been initialized and started:

```sh
podman.exe info
podman.exe run --rm hello-world
```

## License

[MIT](LICENSE)
