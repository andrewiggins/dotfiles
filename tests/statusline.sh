#!/usr/bin/env bash
# Test the Claude Code statusline script by feeding it synthetic JSON and
# verifying the output matches expectations. Requires jq.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_DIR/home/.claude/statusline-command.sh"

errors=0

assert_eq() {
	local label="$1" expected="$2" actual="$3"
	if [ "$expected" = "$actual" ]; then
		echo "  ok: $label"
	else
		echo "FAIL: $label"
		echo "      expected: $expected"
		echo "      actual:   $actual"
		errors=$((errors + 1))
	fi
}

run() {
	echo "$1" | HOME="$fake" sh "$SCRIPT"
}

run_win() {
	echo "$1" | HOME='C:\Users\testuser' sh "$SCRIPT"
}

fake="$(mktemp -d)"
trap 'rm -rf "$fake"' EXIT

echo "=== statusline tests ==="

# --- Path shortening ---

assert_eq "deep path truncates to last 3" \
	"…/github/andrewiggins/dotfiles | Opus 4" \
	"$(run '{"workspace":{"current_dir":"/a/b/github/andrewiggins/dotfiles"},"model":{"display_name":"Opus 4"}}')"

assert_eq "home dir shows ~" \
	"~ | Opus 4" \
	"$(run '{"workspace":{"current_dir":"'"$fake"'"},"model":{"display_name":"Opus 4"}}')"

# shellcheck disable=SC2088 # ~ is the expected literal output, not a path
assert_eq "home subdir stays short" \
	"~/projects/foo | Opus 4" \
	"$(run '{"workspace":{"current_dir":"'"$fake"'/projects/foo"},"model":{"display_name":"Opus 4"}}')"

assert_eq "deep home path truncates after ~" \
	"…/b/c/d | Opus 4" \
	"$(run '{"workspace":{"current_dir":"'"$fake"'/a/b/c/d"},"model":{"display_name":"Opus 4"}}')"

assert_eq "short absolute path unchanged" \
	"/tmp | Opus 4" \
	"$(run '{"workspace":{"current_dir":"/tmp"},"model":{"display_name":"Opus 4"}}')"

# --- Windows paths ---

assert_eq "windows backslash path truncates" \
	"…/some/deep/path | Opus 4" \
	"$(run_win '{"workspace":{"current_dir":"C:\\code\\projects\\some\\deep\\path"},"model":{"display_name":"Opus 4"}}')"

assert_eq "windows home dir shows ~" \
	"~ | Opus 4" \
	"$(run_win '{"workspace":{"current_dir":"C:\\Users\\testuser"},"model":{"display_name":"Opus 4"}}')"

# shellcheck disable=SC2088
assert_eq "windows home subdir stays short" \
	"~/projects/foo | Opus 4" \
	"$(run_win '{"workspace":{"current_dir":"C:\\Users\\testuser\\projects\\foo"},"model":{"display_name":"Opus 4"}}')"

assert_eq "windows deep home path truncates" \
	"…/b/c/d | Opus 4" \
	"$(run_win '{"workspace":{"current_dir":"C:\\Users\\testuser\\a\\b\\c\\d"},"model":{"display_name":"Opus 4"}}')"

# --- Git branch ---

# Run from inside the repo itself so git branch resolves
assert_eq "git branch appears" \
	"$(run '{"workspace":{"current_dir":"'"$REPO_DIR"'"},"model":{"display_name":"Opus 4"}}' | grep -o '| [^ ]* | Opus' || echo "NO MATCH")" \
	"| $(git -C "$REPO_DIR" symbolic-ref --short HEAD 2>/dev/null) | Opus"

# --- Optional sections ---

assert_eq "context percentage shown" \
	"~ | Opus 4 | ctx: 42%" \
	"$(run '{"workspace":{"current_dir":"'"$fake"'"},"model":{"display_name":"Opus 4"},"context_window":{"used_percentage":42.3}}')"

assert_eq "rate limit without resets_at falls back to 5h" \
	"~ | Opus 4 | 5h: 15%" \
	"$(run '{"workspace":{"current_dir":"'"$fake"'"},"model":{"display_name":"Opus 4"},"rate_limits":{"five_hour":{"used_percentage":15.1}}}')"

resets_2h=$(($(date +%s) + 7200))
assert_eq "rate limit shows countdown with resets_at" \
	"~ | Opus 4 | 1h59m: 30%" \
	"$(run '{"workspace":{"current_dir":"'"$fake"'"},"model":{"display_name":"Opus 4"},"rate_limits":{"five_hour":{"used_percentage":30,"resets_at":'"$resets_2h"'}}}')"

resets_30m=$(($(date +%s) + 1800))
assert_eq "rate limit shows minutes only when under 1h" \
	"~ | Opus 4 | 29m: 50%" \
	"$(run '{"workspace":{"current_dir":"'"$fake"'"},"model":{"display_name":"Opus 4"},"rate_limits":{"five_hour":{"used_percentage":50,"resets_at":'"$resets_30m"'}}}')"

resets_past=$(($(date +%s) - 60))
assert_eq "rate limit shows 5h when resets_at is in the past" \
	"~ | Opus 4 | 5h: 5%" \
	"$(run '{"workspace":{"current_dir":"'"$fake"'"},"model":{"display_name":"Opus 4"},"rate_limits":{"five_hour":{"used_percentage":5,"resets_at":'"$resets_past"'}}}')"

assert_eq "all sections together" \
	"~ | Opus 4 | ctx: 50% | 5h: 25%" \
	"$(run '{"workspace":{"current_dir":"'"$fake"'"},"model":{"display_name":"Opus 4"},"context_window":{"used_percentage":50},"rate_limits":{"five_hour":{"used_percentage":25}}}')"

assert_eq "missing model omitted" \
	"~" \
	"$(run '{"workspace":{"current_dir":"'"$fake"'"}}')"

if [ "$errors" -gt 0 ]; then
	echo
	echo "FAILED: $errors error(s)"
	exit 1
fi

echo
echo "All statusline tests passed."
