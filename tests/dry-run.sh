#!/usr/bin/env bash
# Integration test: run install.sh against a temporary HOME and verify that
# the expected symlinks were created. Used by CI.
#
# Setting HOME to a temp dir isolates everything: symlinks land in the temp
# dir, and `git config --global` writes to $temp/.gitconfig instead of the
# real one.
set -euo pipefail

# Git Bash on Windows copies files instead of creating symlinks unless this
# is set. No effect on Linux/macOS CI runners.
export MSYS=winsymlinks:nativestrict

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fake="$(mktemp -d)"
trap 'rm -rf "$fake"' EXIT

# Verify expected symlinks exist
expected=(
	".bashrc"
	".vimrc"
	".editorconfig"
	".config/starship.toml"
)

# .zshrc / .zprofile only on Darwin
if [ "$(uname -s)" = "Darwin" ]; then
	expected+=(".zshrc" ".zprofile")
fi

errors=0

echo "=== Phase 1: DRY_RUN=1 ==="
HOME="$fake" DRY_RUN=1 bash "$REPO_DIR/install.sh"

# Dry-run must not have created anything
if [ -e "$fake/.bashrc" ]; then
	echo "FAIL: dry-run should not have created $fake/.bashrc"
	exit 1
fi

echo
echo "=== Phase 2: real run with SKIP_PACKAGES=1 ==="
HOME="$fake" SKIP_PACKAGES=1 bash "$REPO_DIR/install.sh"

for f in "${expected[@]}"; do
	if [ ! -L "$fake/$f" ]; then
		echo "FAIL: $fake/$f is not a symlink"
		errors=$((errors + 1))
	else
		target="$(readlink "$fake/$f")"
		echo "  ok: $fake/$f -> $target"
	fi
done

# Verify undodir was created
if [ ! -d "$fake/.vim/undodir" ]; then
	echo "FAIL: $fake/.vim/undodir was not created"
	errors=$((errors + 1))
fi

# Verify git config landed in fake HOME, not the real one
if [ ! -f "$fake/.gitconfig" ]; then
	echo "FAIL: $fake/.gitconfig was not created"
	errors=$((errors + 1))
fi

echo
echo "=== Phase 3: idempotency check ==="
HOME="$fake" SKIP_PACKAGES=1 bash "$REPO_DIR/install.sh"

# Symlinks should still be present
for f in "${expected[@]}"; do
	if [ ! -L "$fake/$f" ]; then
		echo "FAIL: after second run, $fake/$f is not a symlink"
		errors=$((errors + 1))
	fi
done

if [ "$errors" -gt 0 ]; then
	echo
	echo "FAILED: $errors error(s)"
	exit 1
fi

echo
echo "All checks passed."
