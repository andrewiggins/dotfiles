#!/usr/bin/env bash
# Install AI coding agents for Unix-like environments and Git Bash on Windows.
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

# Install global skills from a GitHub repo via the skills.sh CLI. Skills land in
# ~/.agents/skills (read by Codex, Pi, and Copilot) and are symlinked into
# agent-specific dirs such as ~/.claude/skills. Already-installed skills are
# skipped so re-runs don't pull newer upstream versions.
install_skills() {
	local source="$1"
	local agents="$2"
	shift 2

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
		echo "npx is required to install skills from $source" >&2
		exit 1
	fi

	echo "Installing skills from $source: ${missing[*]}..."
	# shellcheck disable=SC2086 # agents is a space-separated list
	DISABLE_TELEMETRY=1 npx -y "$SKILLS_CLI" add "$source" --global --yes \
		--agent $agents --skill "${missing[@]}"
}

# Claude Code already gets skill-creator and frontend-design from claude.ai
# sync, so only link these into the other agents.
install_skills anthropics/skills "codex pi github-copilot" \
	skill-creator frontend-design
install_skills openai/skills "claude-code codex pi github-copilot" \
	security-best-practices security-ownership-map security-threat-model
