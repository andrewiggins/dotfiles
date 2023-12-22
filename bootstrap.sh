#!/usr/bing/env bash
set -e

cd "$(dirname "${BASH_SOURCE}")";

git pull origin main;

curl -sS https://starship.rs/install.sh | sh

curl https://get.volta.sh | bash
volta install node
