# Container Testing Plan

## Goal

Run `install.sh` in its entirety inside a Linux container, then verify everything was installed correctly. This catches real breakage from upstream package changes, missing dependencies, or script regressions that `SKIP_PACKAGES=1` dry-run testing cannot.

## New Files

```text
tests/linux/
├── run-container-tests.sh       # Local + CI test runner
├── verify-install.sh            # Post-install verification (runs inside container)
└── Containerfile.ubuntu
.github/workflows/ci.yml         # Extended with docker-test job
```

---

## Containerfile (`tests/linux/Containerfile.ubuntu`)

Single container build file targeting Ubuntu 24.04:

```dockerfile
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root

# Scripts use sudo/curl/git — base images lack them
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo curl ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

COPY . /dotfiles
WORKDIR /dotfiles

CMD ["bash", "-c", "bash /dotfiles/install.sh && bash /dotfiles/tests/linux/verify-install.sh"]
```

### Design decisions

- **Run as root with sudo installed**: The install scripts call `sudo apt`. Running as root with sudo installed means sudo is a no-op pass-through — simplest approach.
- **`COPY . /dotfiles`**: Makes images self-contained and works identically in CI. The test runner builds fresh images each time.
- **Single distro**: Starting with Ubuntu 24.04 only. More distros can be added later if needed.

---

## Verification Script (`tests/linux/verify-install.sh`)

Runs inside the container after `install.sh` completes. Checks every artifact the installer claims to create.

### Path setup

Cargo and Volta binaries are not on `$PATH` by default in the verification context:

```bash
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$HOME/.local/bin:$PATH"
```

### Full Linux checks (default)

| Category | What to verify | How |
|----------|---------------|-----|
| **Symlinks** | `.bashrc`, `.vimrc`, `.editorconfig`, `.config/starship.toml`, `.claude/statusline-command.sh` | `[ -L "$HOME/<file>" ]` and verify target points into `/dotfiles/home/` |
| **Directories** | `~/.vim/undodir` | `[ -d "$HOME/.vim/undodir" ]` |
| **apt packages** | gcc, cmake, curl, git, jq, vim | `command -v <binary>` |
| **ripgrep** | Installed via .deb | `command -v rg` |
| **Rust** | rustup + cargo | `command -v cargo && command -v rustc` |
| **Cargo packages** | bat, delta, starship | `command -v bat && command -v delta && command -v starship` |
| **gh CLI** | GitHub CLI | `command -v gh` |
| **Volta + Node** | Volta dir, node, pnpm | `[ -d "$HOME/.volta" ]`, `command -v node`, `command -v pnpm` |
| **Git config** | Identity, aliases, pager | `git config --global user.name` = "Andre Wiggins", `alias.st` = "status -s", `core.pager` = "delta" |
| **Claude config** | settings.json with statusLine | `[ -f "$HOME/.claude/settings.json" ]`, verify `statusLine` key via jq |

### Codespaces checks (`CODESPACES=true`)

When `CODESPACES=true` is set, `install.sh` runs `install-packages-codespaces.sh` instead of `install-packages-linux.sh`. The verification script detects this and adjusts:

- **Skip**: apt packages (build-essential, cmake, ripgrep, gh), rust/cargo, cargo packages (bat, delta)
- **Check**: starship (installed to `~/.local/bin`), volta, node, pnpm
- **Git config**: Should NOT have `core.pager = delta` (codespaces path sets `IS_CODESPACES=1`)
- **Symlinks**: Same as full Linux (minus `.zshrc`/`.zprofile` which are macOS-only)

### Output format

```
ok:   symlink ~/.bashrc -> /dotfiles/home/.bashrc
ok:   command gcc found
FAIL: command bat not found
...
Results: 18 passed, 1 failed
```

Exit code = number of failures (0 on success).

---

## Test Runner (`tests/linux/run-container-tests.sh`)

### Usage

```bash
bash tests/linux/run-container-tests.sh [OPTIONS] [TEST...]

Tests: full, codespaces
  If none specified, runs all.

Options:
  --no-cleanup    Keep containers alive after tests (for debugging)
```

### Behavior

1. **Detect runtime**: Uses `podman` if available, falls back to `docker`.
2. **Build**: `<runtime> build -f tests/linux/Containerfile.ubuntu -t dotfiles-test:ubuntu .`
3. **Run**: Execute the requested tests (`full`, `codespaces`, or both by default).
4. **Summary**: Print pass/fail result. Exit non-zero if any test failed.
5. **Cleanup** (default): `<runtime> rm -f` all created containers via a `trap` on exit.
6. **--no-cleanup**: Skip container removal. Print debug instructions:
   ```
   Container kept: dotfiles-test-ubuntu-1712937600
     Debug:   podman exec -it dotfiles-test-ubuntu-1712937600 bash
     Cleanup: podman rm -f dotfiles-test-ubuntu-1712937600
   ```

### Design decisions

- **Podman-first, Docker fallback**: The runner auto-detects the container runtime. Locally this uses Podman; CI on GitHub Actions uses Docker (pre-installed on runners).
- **No compose layer**: Plain `build` + `run` commands have no extra dependencies and there's no inter-container networking to manage.
- **No bind mounts**: `COPY` in the Containerfile makes images self-contained. Rebuilding is fast since only the `COPY` layer changes.

---

## CI Integration

Add a `docker-test` job to `.github/workflows/ci.yml` alongside the existing `test` job:

```yaml
docker-test:
  runs-on: ubuntu-latest
  timeout-minutes: 30
  steps:
    - uses: actions/checkout@v4

    - name: Run container tests
      run: bash tests/linux/run-container-tests.sh
```

### Notes

- **30-minute timeout**: `cargo install --locked bat git-delta starship` compiles from source (~5-15 min).
- Runs on the same triggers as existing CI (push, PR, weekly Monday 9 AM UTC).

---

## Verification Checklist

1. **All tests**: `bash tests/linux/run-container-tests.sh`
2. **Full install only**: `bash tests/linux/run-container-tests.sh full`
3. **Codespaces only**: `bash tests/linux/run-container-tests.sh codespaces`
4. **Debug mode**: `bash tests/linux/run-container-tests.sh --no-cleanup full` then `podman exec -it <name> bash`
5. **CI**: Push branch, verify `docker-test` job passes in GitHub Actions

---

## Known Limitations

- **amd64 only**: The ripgrep `.deb` download and CI runners are amd64. Apple Silicon local testing needs `docker run --platform linux/amd64`.
- **Single distro**: Ubuntu 24.04 only. `install-packages-linux.sh` is apt-only, so no Fedora/RHEL support without refactoring.
- **Rust compilation is slow**: 5-15 minutes for bat+delta+starship from source. No workaround short of switching to pre-built binaries.
- **Network dependent**: Scripts download from github.com, rustup.rs, get.volta.sh, starship.rs, cli.github.com. Transient failures will fail the test. The weekly CI schedule helps distinguish transient vs. real issues.
