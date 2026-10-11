#!/usr/bin/env bash
# macOS package install via Homebrew + Podman + Volta.
# Honors SKIP_PACKAGES=1 for CI dry-runs.
set -euo pipefail

if [ "${SKIP_PACKAGES:-0}" = "1" ]; then
	echo "SKIP_PACKAGES=1, skipping macOS package install"
	exit 0
fi

# Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
	echo "Installing Homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Do not let `brew install` upgrade already-installed formulae/casks.
export HOMEBREW_NO_INSTALL_UPGRADE=1

# Install packages via Homebrew (idempotent)
brew install \
	bash \
	bat \
	ffmpeg \
	gh \
	git \
	git-delta \
	git-gui \
	git-lfs \
	gnu-tar \
	grep \
	imagemagick \
	jq \
	podman \
	ripgrep \
	rsync \
	starship \
	vim \
	wget

# Install casks
brew install --cask \
	alt-tab \
	font-fira-code \
	font-fira-code-nerd-font \
	git-credential-manager \
	iterm2 \
	mos \
	raycast

# Install Volta
if [ ! -d "$HOME/.volta" ]; then
	curl https://get.volta.sh | bash
fi

# Install Node toolchain
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
# Always configure Volta-managed tools, regardless of other tools on PATH.
volta install node
volta install pnpm
