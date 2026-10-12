#!/usr/bin/env bash
# Exercise Git identity configuration without touching real user/system config.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fake="$(mktemp -d)"
trap 'rm -rf "$fake"' EXIT

# Clear ambient Git config/identity overrides and avoid the checkout's config.
for var in "${!GIT_CONFIG_@}" "${!GIT_AUTHOR_@}" "${!GIT_COMMITTER_@}"; do
	unset "$var"
done
unset GIT_CONFIG GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE EMAIL
unset GIT_EMAIL IS_CODESPACES IS_WSL
cd "$fake"

new_case() {
	export HOME="$fake/$1/home" XDG_CONFIG_HOME="$fake/$1/xdg"
	export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
	export GIT_CONFIG_SYSTEM="$fake/$1/system.gitconfig"
	mkdir -p "$HOME" "$XDG_CONFIG_HOME"
	cp "$REPO_DIR/tests/linux/codespaces.gitconfig" "$GIT_CONFIG_SYSTEM"
}

assert_equal() {
	local label="$1" expected="$2" actual="$3"
	if [ "$actual" != "$expected" ]; then
		printf 'FAIL: %s (expected "%s", got "%s")\n' "$label" "$expected" "$actual" >&2
		exit 1
	fi
	echo "  ok: $label"
}

assert_contains() {
	local label="$1" output="$2" expected="$3"
	if ! grep -Fq "$expected" <<< "$output"; then
		echo "FAIL: $label (missing: $expected)" >&2
		exit 1
	fi
	echo "  ok: $label"
}

assert_absent_global() {
	local key="$1"
	if git config --global --get-all "$key"; then
		echo "FAIL: global $key should be unset" >&2
		exit 1
	fi
	echo "  ok: global $key is unset"
}

run_config() {
	bash "$REPO_DIR/scripts/configure-git.sh" 2>&1
}

new_case fresh
system_before="$(git hash-object "$GIT_CONFIG_SYSTEM")"
output="$(IS_CODESPACES=1 run_config)"
assert_contains "Codespaces identity left unchanged" "$output" "Leaving Codespaces Git identity unchanged."
assert_absent_global user.name
assert_absent_global user.email
assert_equal "managed name" "Managed Codespaces User" "$(git config --get user.name)"
assert_equal "managed email" "123+example@users.noreply.github.com" "$(git config --get user.email)"
assert_equal "signing enabled" true "$(git config --get commit.gpgsign)"
assert_equal "managed signer" managed-signing-program "$(git config --get gpg.program)"
assert_equal "managed credentials" managed-credential-helper "$(git config --get credential.helper)"
assert_equal "unrelated defaults configured" main "$(git config --global init.defaultBranch)"
assert_equal "system config untouched" "$system_before" "$(git hash-object "$GIT_CONFIG_SYSTEM")"

before="$(git hash-object "$GIT_CONFIG_GLOBAL")"
IS_CODESPACES=1 IS_WSL=1 GIT_EMAIL='' run_config >/dev/null
assert_equal "repeat setup is byte-identical, even with WSL signals" "$before" "$(git hash-object "$GIT_CONFIG_GLOBAL")"

new_case system-include
cp "$GIT_CONFIG_SYSTEM" "$HOME/managed.gitconfig"
git config --file "$GIT_CONFIG_SYSTEM" --remove-section user
git config --file "$GIT_CONFIG_SYSTEM" include.path "$HOME/managed.gitconfig"
output="$(IS_CODESPACES=1 run_config)"
assert_equal "system include email preserved" "123+example@users.noreply.github.com" "$(git config --get user.email)"
assert_equal "complete included identity has no warning" 0 "$(grep -c 'Warning:' <<< "$output" || true)"
assert_absent_global user.email

# Forward-only fix: neither old defaults nor intentional values are migrated.
for identity in andrewiggins@live.com custom@example.test; do
	new_case "$identity"
	git config --global user.name "Andre Wiggins"
	git config --global user.email "$identity"
	git config --global custom.preserved yes
	IS_CODESPACES=1 run_config >/dev/null
	assert_equal "existing identity is not migrated" "$identity" "$(git config --global user.email)"
	assert_equal "existing name preserved" "Andre Wiggins" "$(git config --global user.name)"
	assert_equal "unrelated global config preserved" yes "$(git config --global custom.preserved)"
done

new_case global-include
git config --file "$HOME/intentional.gitconfig" user.name "Intentional User"
git config --file "$HOME/intentional.gitconfig" user.email included@example.test
git config --global include.path "$HOME/intentional.gitconfig"
included_before="$(git hash-object "$HOME/intentional.gitconfig")"
IS_CODESPACES=1 run_config >/dev/null
assert_equal "global included identity preserved" included@example.test "$(git config --get user.email)"
assert_equal "global include file untouched" "$included_before" "$(git hash-object "$HOME/intentional.gitconfig")"

new_case explicit-override
output="$(IS_CODESPACES=1 GIT_EMAIL=override@example.test run_config)"
assert_contains "Codespaces override warns about signing" "$output" "may break managed signing"
assert_equal "explicit Codespaces email honored" override@example.test "$(git config --global user.email)"
assert_absent_global user.name
assert_equal "explicit override preserves signing" true "$(git config --get commit.gpgsign)"
before="$(git hash-object "$GIT_CONFIG_GLOBAL")"
IS_CODESPACES=1 GIT_EMAIL=override@example.test run_config >/dev/null
assert_equal "explicit override is idempotent" "$before" "$(git hash-object "$GIT_CONFIG_GLOBAL")"

new_case missing-identity
git config --file "$GIT_CONFIG_SYSTEM" --remove-section user
output="$(IS_CODESPACES=1 run_config)"
assert_contains "missing managed identity warns" "$output" "managed signing compatibility is not established"
assert_absent_global user.name
assert_absent_global user.email
assert_equal "missing identity still configures defaults" main "$(git config --global init.defaultBranch)"

new_case repository-overrides
git init -q "$HOME/repository"
cd "$HOME/repository"
git config user.email repository@example.test
local_before="$(git hash-object .git/config)"
IS_CODESPACES=1 run_config >/dev/null
assert_equal "repository-local identity preserved" repository@example.test "$(git config --get user.email)"
assert_equal "repository config untouched" "$local_before" "$(git hash-object .git/config)"
export GIT_AUTHOR_NAME="Environment Author" GIT_AUTHOR_EMAIL=author@example.test
export GIT_COMMITTER_NAME=GitHub GIT_COMMITTER_EMAIL=noreply@github.com
IS_CODESPACES=1 run_config >/dev/null
assert_contains "author environment preserved" "$(git var GIT_AUTHOR_IDENT)" "Environment Author <author@example.test>"
assert_contains "managed committer environment preserved" "$(git var GIT_COMMITTER_IDENT)" "GitHub <noreply@github.com>"
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
cd "$fake"

new_case local-default
IS_CODESPACES=0 run_config >/dev/null
assert_equal "local default name" "Andre Wiggins" "$(git config --global user.name)"
assert_equal "local default email" andrewiggins@live.com "$(git config --global user.email)"
IS_CODESPACES=0 GIT_EMAIL=override@example.test run_config >/dev/null
assert_equal "local explicit override" override@example.test "$(git config --global user.email)"
IS_CODESPACES=0 GIT_EMAIL='' run_config >/dev/null
assert_equal "local empty override retains default" andrewiggins@live.com "$(git config --global user.email)"

echo "All Git identity tests passed."
