#!/bin/sh
# Claude Code status line — inspired by the Starship prompt config.
# Receives JSON on stdin with workspace, model, and context_window fields.
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
rate=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

# Replace $HOME with ~, then keep last 3 components
short_path=$(echo "$cwd" | sed "s|^$HOME|~|")
short_path=$(echo "$short_path" | awk -F/ '{
  if (NF <= 3) print $0
  else print "…/" $(NF-2) "/" $(NF-1) "/" $NF
}' | tr -d ' ')

parts="$short_path"

if [ -n "$branch" ]; then
  parts="$parts | $branch"
fi

if [ -n "$model" ]; then
  parts="$parts | $model"
fi

if [ -n "$used" ]; then
  parts="$parts | ctx: $(printf '%.0f' "$used")%"
fi

if [ -n "$rate" ]; then
  parts="$parts | 5h: $(printf '%.0f' "$rate")%"
fi

printf "%s" "$parts"
