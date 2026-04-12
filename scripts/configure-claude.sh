#!/usr/bin/env bash
# Idempotent Claude Code configuration. Ensures ~/.claude/settings.json has the
# statusLine command pointing to the dotfiles-managed script. Re-running is safe
# — existing settings are preserved.
#
# Requires: jq
set -euo pipefail

echo "Configuring Claude Code..."

SETTINGS_FILE="$HOME/.claude/settings.json"
STATUSLINE_CMD="bash ~/.claude/statusline-command.sh"

mkdir -p "$HOME/.claude"

if [ ! -f "$SETTINGS_FILE" ]; then
	# Create a minimal settings file with just the statusLine
	cat > "$SETTINGS_FILE" <<-EOF
	{
	  "statusLine": {
	    "type": "command",
	    "command": "$STATUSLINE_CMD"
	  }
	}
	EOF
	echo "    created $SETTINGS_FILE with statusLine"
elif ! command -v jq >/dev/null 2>&1; then
	echo "    WARNING: jq not found — cannot update $SETTINGS_FILE"
	echo "    Add this manually to your settings.json:"
	echo "      \"statusLine\": { \"type\": \"command\", \"command\": \"$STATUSLINE_CMD\" }"
else
	# Merge statusLine into existing settings, preserving everything else
	existing=$(cat "$SETTINGS_FILE")
	current_cmd=$(echo "$existing" | jq -r '.statusLine.command // empty')
	if [ "$current_cmd" = "$STATUSLINE_CMD" ]; then
		echo "    statusLine already configured"
	else
		echo "$existing" | jq --arg cmd "$STATUSLINE_CMD" \
			'.statusLine = { "type": "command", "command": $cmd }' \
			> "$SETTINGS_FILE.tmp"
		mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
		echo "    updated $SETTINGS_FILE with statusLine"
	fi
fi

echo "Claude Code configured."
