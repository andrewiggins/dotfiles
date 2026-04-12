#!/bin/sh
# Claude Code status line — inspired by the Starship prompt config.
# Receives JSON on stdin with workspace, model, and context_window fields.
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
rate=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

# Normalize Windows backslashes to forward slashes
# shellcheck disable=SC1003
cwd=$(echo "$cwd" | tr '\\' '/')
# shellcheck disable=SC1003
home=$(echo "$HOME" | tr '\\' '/')

branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

# Replace $HOME with ~, then keep last 3 components
short_path=$(echo "$cwd" | sed "s|^$home|~|")
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
  rate_label="5h"
  if [ -n "$resets_at" ]; then
    now=$(date +%s)
    remaining=$((${resets_at%.*} - now))
    if [ "$remaining" -gt 0 ]; then
      hours=$((remaining / 3600))
      mins=$(( (remaining % 3600) / 60 ))
      if [ "$hours" -gt 0 ]; then
        rate_label="${hours}h${mins}m"
      else
        rate_label="${mins}m"
      fi
    fi
  fi
  parts="$parts | ${rate_label}: $(printf '%.0f' "$rate")%"
fi

printf "%s" "$parts"
