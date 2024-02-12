#!/usr/bin/env bash
set -e

cd "$(dirname "${BASH_SOURCE}")";

# Ensure latest dotfiles are used
git pull origin main;

# Install starship prompt
mkdir -p ~/.local/bin
curl -sS https://starship.rs/install.sh | sh -s -- -y -b ~/.local/bin
cat >> "$HOME/.bashrc" <<- 'EOF'

	# Init starship prompt
	eval "$(starship init bash)"

	# Set window title to output of starship directory module
	function set_win_title() {
		echo -ne "\033]0; $(echo $(starship module directory) | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g") \007"
	}

	starship_precmd_user_func="set_win_title"
EOF

# Install volta
curl https://get.volta.sh | bash

echo "CODESPACE_VSCODE_FOLDER=$CODESPACE_VSCODE_FOLDER"
export

# Do GH codespaces custom initialization
# if [ ! -z "$CODESPACE_VSCODE_FOLDER" ] # Unfortunately, this env var is available when this script runs
if [ "$CODESPACES" == "true" ]
then
  cp ./.config/starship.toml "$HOME/.config/starship.toml"

  # Set default branch name to "main"
  git config --global init.defaultBranch main

  # Git aliases
  git config --global alias.unstage 'reset HEAD --'
  git config --global alias.co checkout
  git config --global alias.br branch
  git config --global alias.ci commit
  git config --global alias.st "status -s"
  git config --global alias.amend 'commit --amend --no-edit'
  git config --global alias.type "cat-file -t"
  git config --global alias.dump "cat-file -p"
  git config --global alias.sl "stash list"
  git config --global alias.ss "stash save"
  git config --global alias.sp "stash pop"
  git config --global alias.sa "stash apply"
  git config --global alias.cp cherry-pick
  git config --global alias.last 'log -1 HEAD'
  git config --global alias.hist 'log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short'

  # Git remote origin aliases
  git config --global alias.origin 'remote show origin'
  git config --global alias.up 'remote update origin --prune'

  # Doesn't work cuz this env var isn't available to dotfiles installation
  # pushd $CODESPACE_VSCODE_FOLDER
  # $HOME/.volta/bin/node --version
  # popd
fi

# Load .bashrc
source "$HOME/.bashrc"
