#!/usr/bin/env bash
# Linux/WSL package install: apt + rustup + cargo + gh + volta.
# Honors SKIP_PACKAGES=1 for CI dry-runs.
set -euo pipefail

if [ "${SKIP_PACKAGES:-0}" = "1" ]; then
	echo "SKIP_PACKAGES=1, skipping linux package install"
	exit 0
fi

sudo apt update
sudo apt upgrade -y
sudo apt install -y \
	build-essential \
	cmake \
	curl \
	git \
	git-gui \
	jq \
	vim

# Install ripgrep
RG_VERSION=14.1.1
if ! command -v rg >/dev/null 2>&1; then
	curl -LO "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep_${RG_VERSION}-1_amd64.deb"
	sudo dpkg -i "ripgrep_${RG_VERSION}-1_amd64.deb"
	rm "ripgrep_${RG_VERSION}-1_amd64.deb"
fi

# Install Rust toolchain
if ! command -v cargo >/dev/null 2>&1; then
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
# shellcheck disable=SC1091
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Install Rust packages
cargo install --locked bat git-delta starship

# Install GitHub CLI
if ! command -v gh >/dev/null 2>&1; then
	(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
		&& sudo mkdir -p -m 755 /etc/apt/keyrings \
		&& out=$(mktemp) && wget -nv -O"$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
		&& sudo cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
		&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
		&& sudo mkdir -p -m 755 /etc/apt/sources.list.d \
		&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
		&& sudo apt update \
		&& sudo apt install gh -y
fi

# Install Volta
if [ ! -d "$HOME/.volta" ]; then
	curl https://get.volta.sh | bash
fi
