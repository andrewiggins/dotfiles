#!/usr/bin/env bash
# Post-install verification: checks that install.sh set up everything correctly.
# Runs inside the Docker container after install.sh completes.
# Detects CODESPACES=true and adjusts expectations accordingly.
set -uo pipefail

passed=0
failed=0

ok() {
	echo "  ok: $1"
	((passed++))
}

fail() {
	echo "  FAIL: $1"
	((failed++))
}

check_symlink() {
	local file="$1"
	local target_prefix="$2"
	if [ -L "$HOME/$file" ]; then
		local target
		target="$(readlink "$HOME/$file")"
		if [[ "$target" == "$target_prefix"* ]]; then
			ok "symlink ~/$file -> $target"
		else
			fail "symlink ~/$file points to $target, expected prefix $target_prefix"
		fi
	else
		fail "symlink ~/$file does not exist"
	fi
}

check_command() {
	local cmd="$1"
	if command -v "$cmd" >/dev/null 2>&1; then
		ok "command $cmd found"
	else
		fail "command $cmd not found"
	fi
}

check_any_command() {
	local label="$1"
	shift

	for cmd in "$@"; do
		if command -v "$cmd" >/dev/null 2>&1; then
			ok "command $label found via $cmd"
			return
		fi
	done

	fail "command $label not found (checked: $*)"
}

check_dir() {
	local dir="$1"
	if [ -d "$dir" ]; then
		ok "directory $dir exists"
	else
		fail "directory $dir does not exist"
	fi
}

check_git_config() {
	local key="$1"
	local expected="$2"
	local actual
	actual="$(git config --global "$key" 2>/dev/null || echo "")"
	if [ "$actual" = "$expected" ]; then
		ok "git config $key = $expected"
	else
		fail "git config $key = '$actual', expected '$expected'"
	fi
}

check_git_config_absent() {
	local key="$1"
	local actual
	actual="$(git config --global "$key" 2>/dev/null || echo "")"
	if [ -z "$actual" ]; then
		ok "git config $key is unset"
	else
		fail "git config $key = '$actual', expected unset"
	fi
}

check_file() {
	local file="$1"
	if [ -f "$file" ]; then
		ok "file $file exists"
	else
		fail "file $file does not exist"
	fi
}

# --- Setup PATH for installed tools ----------------------------------------

# shellcheck disable=SC1091
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$HOME/.local/bin:$PATH"

is_codespaces=0
if [ "${CODESPACES:-}" = "true" ]; then
	is_codespaces=1
fi

echo "==> Verifying install (codespaces=$is_codespaces)"

# --- Symlinks ---------------------------------------------------------------

echo "--- Symlinks"
check_symlink ".bashrc" "/dotfiles/home/"
check_symlink ".vimrc" "/dotfiles/home/"
check_symlink ".editorconfig" "/dotfiles/home/"
check_symlink ".config/starship.toml" "/dotfiles/home/"
check_symlink ".claude/statusline-command.sh" "/dotfiles/home/"

# --- Directories ------------------------------------------------------------

echo "--- Directories"
check_dir "$HOME/.vim/undodir"

# --- Packages ---------------------------------------------------------------

if [ "$is_codespaces" = "0" ]; then
	echo "--- apt packages"
	check_command gcc
	check_command cmake
	check_command curl
	check_command ffmpeg
	check_command git
	check_any_command imagemagick magick convert
	check_command jq
	check_command vim

	echo "--- AI agents"
	check_command claude
	check_command codex
	check_command pi

	echo "--- ripgrep"
	check_command rg

	echo "--- Rust"
	check_command cargo
	check_command rustc

	echo "--- Cargo packages"
	check_command bat
	check_command delta
	check_command starship

	echo "--- GitHub CLI"
	check_command gh
else
	echo "--- Codespaces packages"
	check_command starship

	echo "--- AI agents"
	check_command claude
	check_command codex
	check_command pi
fi

echo "--- Volta + Node"
check_dir "$HOME/.volta"
check_command node
check_command pnpm

# --- Git config -------------------------------------------------------------

echo "--- Git config"
check_git_config "user.name" "Andre Wiggins"
check_git_config "user.email" "andrewiggins@live.com"
check_git_config "init.defaultBranch" "main"
check_git_config "push.autoSetupRemote" "true"
check_git_config "alias.st" "status -s"
check_git_config "alias.co" "checkout"
check_git_config "filter.lfs.required" "true"

if [ "$is_codespaces" = "0" ]; then
	check_git_config "core.pager" "delta"
	check_git_config "delta.side-by-side" "true"
else
	check_git_config_absent "core.pager"
fi

# --- Claude config ----------------------------------------------------------

echo "--- Claude config"
check_file "$HOME/.claude/settings.json"
if [ -f "$HOME/.claude/settings.json" ] && command -v jq >/dev/null 2>&1; then
	if jq -e '.statusLine.command' "$HOME/.claude/settings.json" >/dev/null 2>&1; then
		ok "Claude settings.json has statusLine.command"
	else
		fail "Claude settings.json missing statusLine.command"
	fi
fi

# --- Summary ----------------------------------------------------------------

echo ""
echo "Results: $passed passed, $failed failed"
exit "$failed"
