#!/usr/bin/env bash
# Verify privilege checks using dry-run only, even if the root guard regresses.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fake="$(mktemp -d)"
trap 'rm -rf "$fake"' EXIT

assert_rejected() {
	local output
	if output="$("$@" env HOME="$fake" DRY_RUN=1 SKIP_PACKAGES=1 bash "$REPO_DIR/install.sh" 2>&1)"; then
		echo "FAIL: root dry-run succeeded"
		exit 1
	fi
	if ! grep -Fq 'Do not run the dotfiles installer as root' <<< "$output"; then
		echo "FAIL: missing root rejection message: $output"
		exit 1
	fi
	if [ -n "$(find "$fake" -mindepth 1 -print -quit)" ]; then
		echo "FAIL: rejected install changed HOME"
		exit 1
	fi
	echo "  ok: root dry-run rejected without changes"
}

if [ "$EUID" -eq 0 ]; then
	assert_rejected
else
	HOME="$fake" DRY_RUN=1 bash "$REPO_DIR/install.sh" > /dev/null
	if [ -n "$(find "$fake" -mindepth 1 -print -quit)" ]; then
		echo "FAIL: normal-user dry-run changed HOME"
		exit 1
	fi
	echo "  ok: normal-user dry-run allowed without changes"

	if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
		assert_rejected sudo -n
	else
		echo "SKIP: root rejection requires root or passwordless sudo (available in CI)"
	fi
fi
