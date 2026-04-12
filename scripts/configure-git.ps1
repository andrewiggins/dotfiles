# Idempotent git config for Windows. Re-running overwrites identical values;
# individual blocks can be commented out per-machine.
#
# Environment overrides:
#   $env:GIT_EMAIL  — defaults to andrewiggins@live.com

$ErrorActionPreference = "Stop"

Write-Host "Configuring git..."

$gitEmail = if ($env:GIT_EMAIL) { $env:GIT_EMAIL } else { "andrewiggins@live.com" }

# --- Identity ---------------------------------------------------------------
git config --global user.name "Andre Wiggins"
git config --global user.email "$gitEmail"

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

# --- delta pager + VS Code merge tool ---------------------------------------
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

# --- Gist push URL rewrite --------------------------------------------------
git config --global url."git@gist.github.com:".pushInsteadOf "https://gist.github.com/andrewiggins"

# --- LFS filter -------------------------------------------------------------
git config --global filter.lfs.required true
git config --global filter.lfs.clean 'git-lfs clean -- %f'
git config --global filter.lfs.smudge 'git-lfs smudge -- %f'
git config --global filter.lfs.process 'git-lfs filter-process'

Write-Host "Git configured (email=$gitEmail)."
