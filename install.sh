#!/usr/bin/env bash
# dotfiles installer for Linux, macOS, WSL, and GitHub Codespaces.
#
# Symlinks files in home/ into $HOME, runs platform-appropriate package and AI
# agent install scripts, then configures git and Claude Code. Idempotent —
# safe to re-run.
#
# Environment overrides:
#   DRY_RUN=1         Print actions without modifying anything.
#   HOME=...          Install into this directory (for tests; affects symlinks
#                     and `git config --global` location).
#   SKIP_PACKAGES=1   Skip running package install + macOS configure scripts.
#   GIT_EMAIL=...     Override git email passed to configure-git.sh.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN="${DRY_RUN:-0}"
SKIP_PACKAGES="${SKIP_PACKAGES:-0}"

# --- 1. Detect environment --------------------------------------------------
os="$(uname -s)"
is_codespaces=0
if [ "${CODESPACES:-}" = "true" ]; then
	is_codespaces=1
fi
is_wsl=0
if [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSL_INTEROP:-}" ] || grep -qi microsoft /proc/version 2>/dev/null; then
	is_wsl=1
fi

echo "==> dotfiles install"
echo "    repo:       $REPO_DIR"
echo "    home:       $HOME"
echo "    os:         $os"
echo "    codespaces: $is_codespaces"
echo "    wsl:        $is_wsl"
echo "    dry-run:    $DRY_RUN"

# --- 2. Symlink files in home/ ----------------------------------------------
link() {
	local src="$1" dest="$2"
	if [ "$DRY_RUN" = "1" ]; then
		echo "    would link $dest -> $src"
		return
	fi
	mkdir -p "$(dirname "$dest")"
	ln -snf "$src" "$dest"
	echo "    linked $dest -> $src"
}

echo "==> Linking dotfiles"
while IFS= read -r -d '' f; do
	rel="${f#"$REPO_DIR"/home/}"
	# Skip macOS-only files on non-Darwin
	case "$rel" in
		.zshrc|.zprofile)
			if [ "$os" != "Darwin" ]; then
				continue
			fi
			;;
	esac
	link "$f" "$HOME/$rel"
done < <(find "$REPO_DIR/home" -type f -print0)

if [ "$DRY_RUN" != "1" ]; then
	mkdir -p "$HOME/.vim/undodir"
fi

# --- 3. Install packages ----------------------------------------------------
echo "==> Installing packages"
if [ "$DRY_RUN" = "1" ]; then
	echo "    (dry-run, skipping package install)"
elif [ "$is_codespaces" = "1" ]; then
	SKIP_PACKAGES="$SKIP_PACKAGES" bash "$REPO_DIR/scripts/install-packages-codespaces.sh"
elif [ "$os" = "Darwin" ]; then
	SKIP_PACKAGES="$SKIP_PACKAGES" bash "$REPO_DIR/scripts/install-packages-macos.sh"
	SKIP_PACKAGES="$SKIP_PACKAGES" bash "$REPO_DIR/scripts/configure-macos.sh"
elif [ "$os" = "Linux" ]; then
	IS_WSL="$is_wsl" SKIP_PACKAGES="$SKIP_PACKAGES" bash "$REPO_DIR/scripts/install-packages-linux.sh"
else
	echo "    unknown OS '$os', skipping package install"
fi

# --- 4. Configure git -------------------------------------------------------
echo "==> Configuring git"
if [ "$DRY_RUN" = "1" ]; then
	echo "    (dry-run, skipping git config)"
else
	IS_CODESPACES="$is_codespaces" IS_WSL="$is_wsl" \
		bash "$REPO_DIR/scripts/configure-git.sh"
fi

# --- 5. Install AI agents ---------------------------------------------------
echo "==> Installing AI agents"
if [ "$DRY_RUN" = "1" ]; then
	echo "    (dry-run, skipping AI agent install)"
else
	bash "$REPO_DIR/scripts/install-ai-agents.sh"
fi

# --- 6. Configure Claude Code -----------------------------------------------
echo "==> Configuring Claude Code"
if [ "$DRY_RUN" = "1" ]; then
	echo "    (dry-run, skipping Claude Code config)"
else
	bash "$REPO_DIR/scripts/configure-claude.sh"
fi

echo "==> Done."
