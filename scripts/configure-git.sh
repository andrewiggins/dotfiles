#!/usr/bin/env bash
# Idempotent git config. Re-running overwrites identical values; individual
# blocks can be commented out per-machine.
#
# Environment overrides:
#   GIT_EMAIL      — defaults to andrewiggins@live.com
#   IS_CODESPACES  — set to "1" to skip delta + VS Code merge tool config
#   IS_WSL         — set to "1" to enable Windows Git Credential Manager
set -euo pipefail

echo "Configuring git..."

GIT_EMAIL="${GIT_EMAIL:-andrewiggins@live.com}"
IS_CODESPACES="${IS_CODESPACES:-0}"
IS_WSL="${IS_WSL:-0}"

# --- Identity ---------------------------------------------------------------
git config --global user.name "Andre Wiggins"
git config --global user.email "$GIT_EMAIL"

# --- Defaults ---------------------------------------------------------------
git config --global init.defaultBranch main
git config --global push.autoSetupRemote true
git config --global rerere.enabled true

# --- Aliases ----------------------------------------------------------------
git config --global alias.unstage 'reset HEAD --'
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st 'status -s'
git config --global alias.amend 'commit --amend --no-edit'
git config --global alias.type 'cat-file -t'
git config --global alias.dump 'cat-file -p'
git config --global alias.sl 'stash list'
git config --global alias.ss 'stash save'
git config --global alias.sp 'stash pop'
git config --global alias.sa 'stash apply'
git config --global alias.cp cherry-pick
git config --global alias.last 'log -1 HEAD'
git config --global alias.hist 'log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short'
git config --global alias.last-change 'log --all -1 --'
git config --global alias.autofetch-branch '!BR=$(git rev-parse --abbrev-ref HEAD) && git remote set-branches --add origin $BR && git fetch origin $BR && git branch -u origin/$BR'
git config --global alias.origin 'remote show origin'
git config --global alias.up 'remote update origin --prune'

# --- delta pager + VS Code merge tool (skip on Codespaces) ------------------
if [ "$IS_CODESPACES" != "1" ]; then
	git config --global core.pager 'delta'
	git config --global interactive.diffFilter 'delta --color-only'
	git config --global add.interactive.useBuiltin false
	git config --global delta.navigate true
	git config --global delta.light false
	git config --global delta.side-by-side true
	git config --global merge.conflictstyle diff3
	git config --global diff.colorMoved default
	git config --global merge.tool code
	git config --global mergetool.code.cmd 'code --wait --merge $REMOTE $LOCAL $BASE $MERGED'
fi

# --- WSL credential helper --------------------------------------------------
# When running under WSL without VS Code on PATH, use the Windows Git Credential
# Manager so credentials are stored via the host OS keychain.
# Ref: https://github.com/git-ecosystem/git-credential-manager/blob/main/docs/wsl.md
if [ "$IS_WSL" = "1" ] && ! command -v code >/dev/null 2>&1; then
	git config --global credential.helper '/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe'
fi

# --- Gist push URL rewrite --------------------------------------------------
git config --global url."git@gist.github.com:".pushInsteadOf "https://gist.github.com/andrewiggins"

# --- LFS filter -------------------------------------------------------------
git config --global filter.lfs.required true
git config --global filter.lfs.clean 'git-lfs clean -- %f'
git config --global filter.lfs.smudge 'git-lfs smudge -- %f'
git config --global filter.lfs.process 'git-lfs filter-process'

echo "Git configured (email=$GIT_EMAIL, codespaces=$IS_CODESPACES, wsl=$IS_WSL)."
