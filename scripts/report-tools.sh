#!/usr/bin/env bash
# Optional PATH inventory. Does not execute discovered tools or modify anything.
# Usage: bash scripts/report-tools.sh [TOOL...]
set -euo pipefail

if [ "$#" -eq 0 ]; then
	set -- git gh bash vim jq rg bat batcat delta starship podman curl \
		volta node npm pnpm cargo rustc python python3 ffmpeg magick claude codex pi
fi

printf 'Executable paths on the current PATH (not package provenance or versions):\n'
for tool in "$@"; do
	if path="$(type -P -- "$tool")"; then
		printf '%s\t%s\n' "$tool" "$path"
	else
		printf '%s\t%s\n' "$tool" 'not found'
	fi
done
