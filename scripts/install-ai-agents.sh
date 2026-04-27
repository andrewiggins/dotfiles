#!/usr/bin/env bash
# Install AI coding agents for Unix-like environments.
# Honors SKIP_PACKAGES=1 for CI dry-runs.
set -euo pipefail

if [ "${SKIP_PACKAGES:-0}" = "1" ]; then
	echo "SKIP_PACKAGES=1, skipping AI agent install"
	exit 0
fi

export VOLTA_HOME="${VOLTA_HOME:-$HOME/.volta}"
export PATH="$VOLTA_HOME/bin:$HOME/.local/bin:$PATH"

install_npm_cli() {
	local command_name="$1"
	local package_name="$2"

	if command -v "$command_name" >/dev/null 2>&1; then
		echo "$command_name already installed"
		return
	fi

	if ! command -v npm >/dev/null 2>&1; then
		echo "npm is required to install $package_name" >&2
		exit 1
	fi

	echo "Installing $package_name..."
	npm install -g "$package_name"
}

if command -v claude >/dev/null 2>&1; then
	echo "claude already installed"
else
	echo "Installing Claude Code via native installer..."
	curl -fsSL https://claude.ai/install.sh | bash
fi

install_npm_cli codex @openai/codex
install_npm_cli pi @mariozechner/pi-coding-agent
