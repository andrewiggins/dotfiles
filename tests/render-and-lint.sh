#!/bin/bash
set -euo pipefail

# Render chezmoi .tmpl files and run ShellCheck on shell output.
# Runs for each machine_type; .chezmoi.os comes from the host OS via matrix.

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Shell templates to lint after rendering
SHELL_TEMPLATES=(
  run_once_before_install-packages.sh.tmpl
  run_once_after_configure-macos.sh.tmpl
  dot_bashrc.tmpl
  dot_zshrc.tmpl
  dot_zprofile.tmpl
)

# Non-shell templates — just verify they render without error
OTHER_TEMPLATES=(
  private_dot_gitconfig.tmpl
  run_once_before_install-packages.ps1.tmpl
)

# Init-only templates use promptStringOnce/promptChoiceOnce
INIT_TEMPLATES=(
  .chezmoi.toml.tmpl
)

errors=0
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi"
source_dir="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"

for machine_type in personal work codespaces; do
  echo "=== machine_type=$machine_type ==="

  # Clean up any prior chezmoi state
  rm -rf "$config_dir" "$source_dir" 2>/dev/null || true

  # Write config BEFORE chezmoi init so promptStringOnce finds existing
  # values and doesn't try to open a TTY.
  mkdir -p "$config_dir"
  cat > "$config_dir/chezmoi.toml" << TOML
[data]
  email = "test@example.com"
  machine_type = "$machine_type"
TOML

  # Initialize chezmoi with our repo as source to get full template context
  # (.chezmoi.os, lookPath, etc.). No --apply so it just sets up source.
  if ! init_output=$(chezmoi init "$REPO_DIR" 2>&1); then
    echo "  ERROR: chezmoi init failed for machine_type=$machine_type"
    echo "  $init_output"
    errors=$((errors + 1))
    continue
  fi

  # Render and lint shell templates
  for tmpl in "${SHELL_TEMPLATES[@]}"; do
    tmpl_path="$REPO_DIR/$tmpl"
    if [ ! -f "$tmpl_path" ]; then
      continue
    fi

    echo "  Rendering $tmpl ..."
    render_output=""
    if ! render_output=$(chezmoi execute-template < "$tmpl_path" 2>&1); then
      echo "  ERROR: Failed to render $tmpl (machine_type=$machine_type)"
      echo "  $render_output"
      errors=$((errors + 1))
      continue
    fi

    # Skip ShellCheck if rendered output is empty (template branch not active on this OS)
    if [ -z "$(echo "$render_output" | tr -d '[:space:]')" ]; then
      echo "  (empty output, skipping shellcheck)"
      continue
    fi

    echo "$render_output" | shellcheck -s bash - || {
      echo "  ERROR: ShellCheck failed for $tmpl (machine_type=$machine_type)"
      errors=$((errors + 1))
    }
  done

  # Render non-shell templates (just check for render errors)
  for tmpl in "${OTHER_TEMPLATES[@]}"; do
    tmpl_path="$REPO_DIR/$tmpl"
    if [ ! -f "$tmpl_path" ]; then
      continue
    fi

    echo "  Rendering $tmpl ..."
    render_output=""
    if ! render_output=$(chezmoi execute-template < "$tmpl_path" 2>&1); then
      echo "  ERROR: Failed to render $tmpl (machine_type=$machine_type)"
      echo "  $render_output"
      errors=$((errors + 1))
    fi
  done

  # Render init-only templates (use --init with prompt flags)
  for tmpl in "${INIT_TEMPLATES[@]}"; do
    tmpl_path="$REPO_DIR/$tmpl"
    if [ ! -f "$tmpl_path" ]; then
      continue
    fi

    echo "  Rendering $tmpl ..."
    render_output=""
    if ! render_output=$(chezmoi execute-template \
      --init \
      --promptChoice machine_type="$machine_type" \
      --promptString email=test@example.com \
      < "$tmpl_path" 2>&1); then
      echo "  ERROR: Failed to render $tmpl (machine_type=$machine_type)"
      echo "  $render_output"
      errors=$((errors + 1))
    fi
  done
done

# Final cleanup
rm -rf "$config_dir" "$source_dir" 2>/dev/null || true

if [ "$errors" -gt 0 ]; then
  echo ""
  echo "FAILED: $errors error(s) found"
  exit 1
fi

echo ""
echo "All templates rendered and linted successfully."
