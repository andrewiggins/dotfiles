#!/usr/bin/env bash
# Linux/WSL package install: apt + podman + rustup + gh + volta + upstream CLIs.
# Honors SKIP_PACKAGES=1 for CI dry-runs.
set -euo pipefail

if [ "${SKIP_PACKAGES:-0}" = "1" ]; then
	echo "SKIP_PACKAGES=1, skipping linux package install"
	exit 0
fi

is_wsl="${IS_WSL:-0}"
if [ "$is_wsl" != "1" ] && { [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSL_INTEROP:-}" ] || grep -qi microsoft /proc/version 2>/dev/null; }; then
	is_wsl=1
fi

sudo apt update
sudo apt upgrade -y
sudo apt install -y \
	build-essential \
	bat \
	cmake \
	curl \
	ffmpeg \
	git \
	git-gui \
	imagemagick \
	jq \
	vim

# Install Podman on native Linux only. WSL uses the Windows host Podman
# machine instead of running a second local container engine.
if [ "$is_wsl" = "1" ]; then
	echo "WSL detected, skipping Podman install. Use the Windows host Podman machine instead."
else
	sudo apt install -y podman
fi

# Install ripgrep
RG_VERSION=14.1.1
if ! command -v rg >/dev/null 2>&1; then
	curl -LO "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep_${RG_VERSION}-1_amd64.deb"
	sudo dpkg -i "ripgrep_${RG_VERSION}-1_amd64.deb"
	rm "ripgrep_${RG_VERSION}-1_amd64.deb"
fi

# Install Rust toolchain for interactive use.
if ! command -v cargo >/dev/null 2>&1; then
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Debian/Ubuntu may install the executable as batcat. Create a stable bat alias
# so shell usage matches other platforms and the upstream docs.
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
	mkdir -p "$HOME/.local/bin"
	ln -snf "$(command -v batcat)" "$HOME/.local/bin/bat"
fi

# Install delta from the latest upstream .deb release.
if ! command -v delta >/dev/null 2>&1; then
	delta_arch="$(dpkg --print-architecture)"
	delta_download_url="$(curl -fsSL https://api.github.com/repos/dandavison/delta/releases/latest | jq -r --arg arch "$delta_arch" '
		[.assets[].browser_download_url
		| select(test("/git-delta_[^/]+_" + $arch + "\\.deb$"))][0] // empty
	')"
	if [ -z "$delta_download_url" ]; then
		echo "Unable to find a git-delta .deb for architecture: $delta_arch" >&2
		exit 1
	fi
	delta_pkg="$(mktemp /tmp/git-delta.XXXXXX.deb)"
	curl -fsSL -o "$delta_pkg" "$delta_download_url"
	sudo dpkg -i "$delta_pkg"
	rm -f "$delta_pkg"
fi

# Install starship via the upstream install script.
if ! command -v starship >/dev/null 2>&1; then
	curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Install GitHub CLI
# From https://github.com/cli/cli/blob/69585cc771a6f85e7628ee934836aab0f8249585/docs/install_linux.md
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

# Install Node toolchain
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
volta install node
volta install pnpm
