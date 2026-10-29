#!/usr/bin/env bash
# Install AI coding agents for Unix-like environments and Git Bash on Windows.
# Honors SKIP_PACKAGES=1 for CI dry-runs.
set -euo pipefail

if [ "${SKIP_PACKAGES:-0}" = "1" ]; then
	echo "SKIP_PACKAGES=1, skipping AI agent install"
	exit 0
fi

case "$(uname -s)" in
	MINGW*|MSYS*|CYGWIN*)
		# Windows Volta lives in %LOCALAPPDATA%\Volta and is already on PATH;
		# pointing VOLTA_HOME at ~/.volta breaks its node/npm/npx shims.
		;;
	*)
		export VOLTA_HOME="${VOLTA_HOME:-$HOME/.volta}"
		export PATH="$VOLTA_HOME/bin:$PATH"
		;;
esac
export PATH="$HOME/.local/bin:$PATH"

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
	case "$(uname -s)" in
		MINGW*|MSYS*|CYGWIN*)
			# Claude's install.sh rejects Git Bash, so use the PowerShell installer.
			# Unset PSModulePath so Windows PowerShell doesn't load PowerShell 7's
			# modules when install.ps1 was launched from pwsh.
			# shellcheck disable=SC2016 # PowerShell expressions, not bash
			env -u PSModulePath powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
				'$ErrorActionPreference = "Stop"; & ([scriptblock]::Create((Invoke-RestMethod -Uri "https://claude.ai/install.ps1")))'
			;;
		*)
			curl -fsSL https://claude.ai/install.sh | bash
			;;
	esac
fi

install_npm_cli codex @openai/codex
install_npm_cli pi @mariozechner/pi-coding-agent

# Pinned so re-runs don't execute a different CLI release than was reviewed.
SKILLS_CLI="skills@1.7.4"

# Install global skills from a GitHub repo, pinned to a commit, via the
# skills.sh CLI. Skills land in ~/.agents/skills (read by Codex, Pi, and
# Copilot) and are symlinked into agent-specific dirs such as ~/.claude/skills.
# Already-installed skills are skipped, so bumping a commit only affects fresh
# installs; `npx skills remove -g <skill>` and re-run to pick up a new commit.
install_skills() {
	local repo="$1"
	local commit="$2"
	local skills_dir="$3"
	local agents="$4"
	shift 4
	local source="https://github.com/$repo/tree/$commit/$skills_dir"

	local missing=()
	local skill
	for skill in "$@"; do
		if [ -f "$HOME/.agents/skills/$skill/SKILL.md" ]; then
			echo "skill $skill already installed"
		else
			missing+=("$skill")
		fi
	done
	[ "${#missing[@]}" -eq 0 ] && return

	if ! command -v npx >/dev/null 2>&1; then
		echo "npx is required to install skills from $repo" >&2
		exit 1
	fi

	echo "Installing skills from $repo@$commit: ${missing[*]}..."
	# shellcheck disable=SC2086 # agents is a space-separated list
	DISABLE_TELEMETRY=1 npx -y "$SKILLS_CLI" add "$source" --global --yes \
		--agent $agents --skill "${missing[@]}"
}

# Claude Code already gets skill-creator and frontend-design from claude.ai
# sync, so only link these into the other agents.
install_skills anthropics/skills ca45fc496a3436251f191354091d557da31c15b5 skills \
	"codex pi github-copilot" \
	skill-creator frontend-design
install_skills openai/skills 49f948faa9258a0c61caceaf225e179651397431 skills/.curated \
	"claude-code codex pi github-copilot" \
	security-best-practices security-ownership-map security-threat-model
