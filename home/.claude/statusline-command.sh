#!/usr/bin/env bash
# Claude Code status line — inspired by the user's Starship prompt config
# Receives JSON on stdin

input=$(cat)

# --- Directory (last 3 components, with ~ substitution) ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
home_dir="$HOME"
short_dir="${cwd/#"$home_dir"/\~}"
# Keep only the last 3 path components; prepend … if truncated
n_slashes="${short_dir//[!\/]/}"
if [ "${#n_slashes}" -gt 3 ]; then
  short_dir="…/$(echo "$short_dir" | awk -F/ '{print $(NF-2)"/"$(NF-1)"/"$NF}')"
fi

# --- Git branch + status (mirrors starship git_branch / git_status) ---
git_part=""
if git_branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null); then
  git_status_flags=""
  # Gather porcelain status
  porcelain=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" status --porcelain 2>/dev/null)
  if [ -n "$porcelain" ]; then
    staged=$(echo "$porcelain" | grep -c '^[MADRC]' || true)
    modified=$(echo "$porcelain" | grep -c '^ [MD]' || true)
    untracked=$(echo "$porcelain" | grep -c '^??' || true)
    [ "$staged" -gt 0 ]    && git_status_flags="${git_status_flags} +${staged}"
    [ "$modified" -gt 0 ]  && git_status_flags="${git_status_flags} ~${modified}"
    [ "$untracked" -gt 0 ] && git_status_flags="${git_status_flags} ?${untracked}"
  fi
  # Ahead/behind
  # shellcheck disable=SC1083 # @{upstream} is git syntax, not shell
  ahead_behind=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-list --left-right --count HEAD...@{upstream} 2>/dev/null || true)
  if [ -n "$ahead_behind" ]; then
    ahead=$(echo "$ahead_behind" | awk '{print $1}')
    behind=$(echo "$ahead_behind" | awk '{print $2}')
    [ "$ahead" -gt 0 ]  && git_status_flags="${git_status_flags} ↑${ahead}"
    [ "$behind" -gt 0 ] && git_status_flags="${git_status_flags} ↓${behind}"
  fi
  git_part=" | ${git_branch}${git_status_flags}"
fi

# --- Model ---
model=$(echo "$input" | jq -r '.model.display_name // ""')

# --- Context usage ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
  ctx_part=" | ctx:$(printf '%.0f' "$used_pct")%"
else
  ctx_part=""
fi

# --- Rate limits (5-hour session, when available) ---
rate_part=""
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$five_pct" ]; then
  rate_part=" 5h:$(printf '%.0f' "$five_pct")%"
fi

printf "%s%s | %s%s%s" "$short_dir" "$git_part" "$model" "$ctx_part" "$rate_part"
