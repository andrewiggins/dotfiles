# dotfiles

Cross-platform dotfiles managed with a plain shell installer and symlinks. Works on Linux, macOS, Windows, and GitHub Codespaces.

## What's configured

- **Git** — aliases, delta pager (side-by-side diffs), VS Code merge tool, LFS, credential helpers
- **Shell** — bash (Linux/WSL), zsh (macOS), PowerShell (Windows) with Starship prompt
- **Vim** — persistent undo, incremental search, sensible defaults
- **EditorConfig** — consistent formatting across editors
- **Starship** — Nerd Font symbols, posh-git style git status
- **AI agents** — Claude Code, Codex, and Pi Coding Agent available from the terminal
- **Media tools** — ffmpeg and ImageMagick on Linux, macOS, and Windows
- **Packages** — platform-specific package installation (apt, Homebrew, winget, upstream release/install scripts)
- **Containers** — Podman on Linux, macOS, and Windows; skipped in GitHub Codespaces

## Install

### GitHub Codespaces

Set this repo as your [dotfiles repository](https://docs.github.com/en/codespaces/customizing-your-codespace/personalizing-github-codespaces-for-your-account#dotfiles) in GitHub settings. `install.sh` runs automatically and detects Codespaces via the `$CODESPACES` env var to do a lightweight setup with Starship, Volta, and the AI agent CLIs, while intentionally skipping ffmpeg and ImageMagick.

### Linux / macOS / WSL

Run as your normal user, not root or with `sudo`. The installer rejects root
execution (including dry-runs); individual system package operations request
`sudo` where needed.

```sh
git clone https://github.com/andrewiggins/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

On native Linux, the installer adds Podman via `apt`.

On WSL, the installer intentionally skips a local Podman daemon and expects you to install Podman on the Windows host instead.

### Windows

Run from a **non-elevated terminal** with Developer Mode enabled (Settings →
Privacy & Security → For developers) so symlinks can be created without elevation.
The installer rejects Administrator execution, including dry-runs. Individual
package installers may show their own elevation prompts; do not elevate the
whole dotfiles installer.

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
5. Installs terminal AI agents (`claude`, `codex`, `pi`) using the platform-appropriate installers.
6. Runs `scripts/configure-claude.sh` to keep Claude Code's statusline wired to the repo-managed script.

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

Re-running the installer recreates symlinks and rewrites Git configuration. It is
an **install-only setup, not a general package upgrade command**. Existing AI
tools are left alone. Apt skips upgrades of already-installed requested packages,
winget uses `--no-upgrade`, and Homebrew install-time upgrades are disabled.

**Volta is an intentional exception:** every package-setup run invokes
`volta install node` and `volta install pnpm` to configure Volta-managed tools,
even if Node or pnpm already exists on PATH. Re-running these commands may change
Volta's selected versions to its current defaults.

Missing packages can still require dependency changes; upstream auto-updaters
and OS update policies remain independent. Maintain security updates separately
using your package managers or the tools' supported update mechanisms.

## Fresh-install version choices

Except for the Volta setup described above, these choices apply when a tool is
missing, not as required versions for existing tools. Fresh installations on
different dates/machines may resolve differently.

| Tool/source | Fresh-install selection |
| --- | --- |
| apt, Homebrew, winget packages | Version available from the configured package-manager sources; no new pins |
| Linux ripgrep direct download | `14.1.1` (`amd64`); macOS/Windows use their package managers |
| Linux delta direct download | Latest GitHub release for the detected architecture |
| Codex / Pi npm installs | Registry default tag for `@openai/codex` / `@mariozechner/pi-coding-agent`; no version specified |
| Claude native installer | Upstream installer's default release/channel |
| Node / pnpm via Volta | Volta's defaults on every package-setup run; existing PATH commands do not suppress Volta installation |
| Rustup, Starship, Volta, Homebrew bootstrappers | Upstream bootstrapper defaults (Starship on macOS/Windows uses the package manager) |
| Windows Nerd Fonts | Current upstream branch; no commit/version pin |

This table documents selection, not verification of package ownership, artifact
integrity, or support status.

## Optional tool-path report

```sh
bash scripts/report-tools.sh
bash scripts/report-tools.sh node pnpm pi
```

On Windows:

```powershell
./scripts/report-tools.ps1
./scripts/report-tools.ps1 -Tools node,pnpm,pi
```

These standalone reports show executable paths on the **current PATH** and
missing tools. They never execute discovered tools, probe versions, install
packages, or change configuration. Reports are not run by the installer or its
dry-run. They do not establish package provenance or identify every installed
package. Inspect versions explicitly with trusted tools (for example,
`node --version` or `pi --version`) or your package manager when needed.

## Test installer privilege checks

```sh
bash tests/install-privileges.sh
```

All elevated installer tests use `DRY_RUN=1`, so a privilege-guard regression
cannot trigger actual installation. Root rejection is tested when running as
root or when passwordless sudo is available (as in CI); otherwise that portion
is explicitly skipped.

On Windows, run `./tests/install-privileges.ps1` in both a normal and an
Administrator PowerShell terminal. The test uses dry-run only and verifies that
the installer allows the normal token and rejects the elevated token.

Full container tests run the installer as a normal user with passwordless sudo
inside the disposable image, not as root. This does not change host sudo policy.

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
