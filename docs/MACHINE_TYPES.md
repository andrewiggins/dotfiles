# Machine types: dropped work-vs-personal differences

The chezmoi-era version of this repo had a `machine_type` setting accepting
`personal | work | codespaces`. In practice only the `codespaces` branch was
ever used in the templates — `personal` and `work` produced identical output —
so the migration to plain shell + symlinks dropped `personal`/`work` entirely.
Codespaces detection now happens at runtime via the `$CODESPACES` env var.

This document captures the **real** work-vs-personal differences from the
*older* `andrewiggins/setup` repo (which predated the chezmoi rewrite), so that
if a work machine ever needs distinct configuration again the historical
context is here.

## Historical differences (from `andrewiggins/setup`)

The old repo had `setup-personal.ps1` and `setup-msft.ps1` for Windows. The
substantive differences:

| Concern                          | Personal (`setup-personal.ps1`) | Work / MSFT (`setup-msft.ps1`)            |
| -------------------------------- | ------------------------------- | ----------------------------------------- |
| Git email                        | `andrewiggins@live.com`         | `andwi@microsoft.com`                     |
| GitHub CLI (`GitHub.cli`)        | Installed                       | Omitted                                   |
| `ripgrep`, `jq` (winget)         | Installed                       | Omitted (likely from internal channels)   |
| `posh-git` PowerShell module     | —                               | Installed + added to profile              |
| `vsts-npm-auth` (Azure DevOps)   | —                               | `npm i -g vsts-npm-auth`                  |
| Cargo: `bat`, `git-delta`        | Installed                       | —                                         |
| Volta + Node toolchain           | Installed                       | —                                         |
| FiraCode Nerd Font               | Installed via custom script     | —                                         |
| `@anthropic-ai/claude-code` npm  | Installed                       | —                                         |
| Starship via winget              | Installed                       | —                                         |
| Post-install reminders           | "Install Outlook PWA"           | "Install Outlook & Teams PWAs"            |

macOS (`setup-mac.sh`) and WSL (`setup-wsl.sh`) had **no** work/personal split
in the old repo — both used the personal email and the same package set.

## How to reintroduce a work/personal split

If a future work machine needs distinct configuration again, the
lowest-overhead path that preserves the new setup's "no template engine, no
stored config file" philosophy is a single env var:

1. Add a `MACHINE_TYPE` check at the top of `install.sh` and `install.ps1`,
   defaulting to `personal`:
   ```bash
   MACHINE_TYPE="${MACHINE_TYPE:-personal}"
   ```
2. In `scripts/install-packages-windows.ps1`, gate the work-only blocks
   (posh-git, vsts-npm-auth) on `$env:MACHINE_TYPE -eq "work"`, and the
   personal-only blocks on `$env:MACHINE_TYPE -ne "work"`.
3. In `scripts/configure-git.sh`, branch on `$MACHINE_TYPE` (passed through
   from `install.sh`) to set the appropriate `user.email`:
   ```bash
   if [ "${MACHINE_TYPE:-personal}" = "work" ]; then
       GIT_EMAIL="${GIT_EMAIL:-andwi@microsoft.com}"
   fi
   ```
4. On the work box, set `MACHINE_TYPE=work` in `~/.extra` (or in the shell
   environment) so re-runs pick it up automatically.

This keeps the env-detection philosophy of the new setup — no stored config
file, no template engine, no prompts on first run — and uses a single
environment variable as the switch.
