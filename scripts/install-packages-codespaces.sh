#!/usr/bin/env bash
# Lightweight Codespaces setup: just starship and volta.
# Podman is intentionally skipped here; Codespaces already provides the
# container runtime.
# Honors SKIP_PACKAGES=1 for CI dry-runs.
set -euo pipefail

if [ "${SKIP_PACKAGES:-0}" = "1" ]; then
	echo "SKIP_PACKAGES=1, skipping codespaces package install"
	exit 0
fi

echo "Codespaces detected, skipping Podman install."

# Install starship prompt
if ! command -v starship >/dev/null 2>&1; then
	echo "Installing starship..."
	mkdir -p ~/.local/bin
	curl -sS https://starship.rs/install.sh | sh -s -- -y -b ~/.local/bin
fi

# Install Volta
if [ ! -d "$HOME/.volta" ]; then
	echo "Installing Volta..."
	curl https://get.volta.sh | bash
fi

# Install Node toolchain
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
volta install node
volta install pnpm
