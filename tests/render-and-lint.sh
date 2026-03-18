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
  .chezmoi.toml.tmpl
  run_once_before_install-packages.ps1.tmpl
)

errors=0

for machine_type in personal work codespaces; do
  echo "=== machine_type=$machine_type ==="

  # Render and lint shell templates
  for tmpl in "${SHELL_TEMPLATES[@]}"; do
    tmpl_path="$REPO_DIR/$tmpl"
    if [ ! -f "$tmpl_path" ]; then
      continue
    fi

    echo "  Rendering $tmpl ..."
    rendered=$(chezmoi execute-template \
      --init \
      --promptChoice machine_type="$machine_type" \
      --promptString email=test@example.com \
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
      --init \
      --promptChoice machine_type="$machine_type" \
      --promptString email=test@example.com \
      < "$tmpl_path" > /dev/null 2>&1 || {
        echo "  ERROR: Failed to render $tmpl (machine_type=$machine_type)"
        errors=$((errors + 1))
      }
  done
done

if [ "$errors" -gt 0 ]; then
  echo ""
  echo "FAILED: $errors error(s) found"
  exit 1
fi

echo ""
echo "All templates rendered and linted successfully."
