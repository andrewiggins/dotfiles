#!/usr/bin/env bash
# Verify environment detection for native Linux, WSL, and Codespaces.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fake="$(mktemp -d)"
trap 'rm -rf "$fake"' EXIT

assert_contains() {
	local label="$1" haystack="$2" needle="$3"
	if printf '%s\n' "$haystack" | grep -Fq "$needle"; then
		echo "  ok: $label"
	else
		echo "FAIL: $label"
		echo "      missing: $needle"
		exit 1
	fi
}

run_install() {
	env HOME="$fake" DRY_RUN=1 "$@" bash "$REPO_DIR/install.sh"
}

echo "=== install mode tests ==="

native_output="$(run_install)"
assert_contains "native linux is not codespaces" "$native_output" "codespaces: 0"
assert_contains "native linux is not wsl" "$native_output" "wsl:        0"

codespaces_output="$(run_install CODESPACES=true)"
assert_contains "codespaces detected" "$codespaces_output" "codespaces: 1"

wsl_output="$(run_install WSL_DISTRO_NAME=Ubuntu)"
assert_contains "wsl detected from env" "$wsl_output" "wsl:        1"

echo
echo "All install mode tests passed."
