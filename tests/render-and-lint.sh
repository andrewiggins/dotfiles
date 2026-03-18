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
# .chezmoi.toml.tmpl uses init-only functions (promptStringOnce, promptChoiceOnce)
# and is tested separately with --init flag
OTHER_TEMPLATES=(
  private_dot_gitconfig.tmpl
  run_once_before_install-packages.ps1.tmpl
)

INIT_TEMPLATES=(
  .chezmoi.toml.tmpl
)

errors=0

# Write chezmoi config to default location so execute-template picks it up.
# This gives templates access to .email, .machine_type, .chezmoi.os, lookPath, etc.
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi"
mkdir -p "$config_dir"

for machine_type in personal work codespaces; do
  echo "=== machine_type=$machine_type ==="

  cat > "$config_dir/chezmoi.toml" << TOML
[data]
  email = "test@example.com"
  machine_type = "$machine_type"
TOML

  # Render and lint shell templates
  for tmpl in "${SHELL_TEMPLATES[@]}"; do
    tmpl_path="$REPO_DIR/$tmpl"
    if [ ! -f "$tmpl_path" ]; then
      continue
    fi

    echo "  Rendering $tmpl ..."
    rendered=$(chezmoi execute-template \
      < "$tmpl_path" 2>&1) || {
        echo "  ERROR: Failed to render $tmpl (machine_type=$machine_type)"
        errors=$((errors + 1))
        continue
      }

    # Skip ShellCheck if rendered output is empty (template branch not active on this OS)
    if [ -z "$(echo "$rendered" | tr -d '[:space:]')" ]; then
      echo "  (empty output, skipping shellcheck)"
      continue
    fi

    echo "$rendered" | shellcheck -s bash - || {
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
    chezmoi execute-template \
      < "$tmpl_path" > /dev/null 2>&1 || {
        echo "  ERROR: Failed to render $tmpl (machine_type=$machine_type)"
        errors=$((errors + 1))
      }
  done

  # Render init-only templates (use --init with prompt flags)
  for tmpl in "${INIT_TEMPLATES[@]}"; do
    tmpl_path="$REPO_DIR/$tmpl"
    if [ ! -f "$tmpl_path" ]; then
      continue
    fi

    echo "  Rendering $tmpl ..."
    chezmoi execute-template \
      --init \
      --promptChoice machine_type="$machine_type" \
      --promptString email=test@example.com \
      < "$tmpl_path" > /dev/null 2>&1 || {
        echo "  ERROR: Failed to render $tmpl (machine_type=$machine_type)"
        errors=$((errors + 1))
      }
  done
done

# Clean up
rm -f "$config_dir/chezmoi.toml"

if [ "$errors" -gt 0 ]; then
  echo ""
  echo "FAILED: $errors error(s) found"
  exit 1
fi

echo ""
echo "All templates rendered and linted successfully."
