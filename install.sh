#!/bin/sh
# Bootstrap script for GitHub Codespaces / Dev Containers
# Installs chezmoi and applies dotfiles non-interactively
set -e

sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply andrewiggins \
  --promptChoice machine_type=codespaces \
  --promptString email=andrewiggins@live.com
