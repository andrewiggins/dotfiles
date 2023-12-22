#!/usr/bin/env bash
set -e

cd "$(dirname "${BASH_SOURCE}")";

# Ensure latest dotfiles are used
git pull origin main;

# Install starship prompt
curl -sS https://starship.rs/install.sh | sh -s -- -b ~/.local/bin
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

# Load .bashrc
source ~/.bashrc
