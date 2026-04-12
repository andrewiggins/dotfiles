#!/usr/bin/env bash
# Run dotfiles install inside Docker containers and verify the result.
#
# Usage:
#   bash tests/docker/run-docker-tests.sh [OPTIONS]
#
# Options:
#   --no-cleanup    Keep containers alive after tests (for debugging)
#   --codespaces    Also run Codespaces-mode test
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cleanup=1
run_codespaces=0
containers=()

# --- Parse arguments --------------------------------------------------------

while [[ $# -gt 0 ]]; do
	case "$1" in
		--no-cleanup)
			cleanup=0
			shift
			;;
		--codespaces)
			run_codespaces=1
			shift
			;;
		*)
			echo "Unknown option: $1" >&2
			echo "Usage: $0 [--no-cleanup] [--codespaces]" >&2
			exit 1
			;;
	esac
done

# --- Cleanup trap -----------------------------------------------------------

# shellcheck disable=SC2329
do_cleanup() {
	if [ "$cleanup" = "1" ]; then
		echo ""
		echo "==> Cleaning up containers"
		for name in "${containers[@]}"; do
			docker rm -f "$name" >/dev/null 2>&1 && echo "    removed $name" || true
		done
	else
		echo ""
		echo "==> Containers kept (--no-cleanup). To debug or clean up:"
		for name in "${containers[@]}"; do
			echo "    docker exec -it $name bash"
			echo "    docker rm -f $name"
		done
	fi
}
trap do_cleanup EXIT

# --- Build ------------------------------------------------------------------

image="dotfiles-test:ubuntu"
echo "==> Building Docker image: $image"
docker build -f "$REPO_DIR/tests/docker/Dockerfile.ubuntu" -t "$image" "$REPO_DIR"

# --- Run tests --------------------------------------------------------------

total=0
failures=0

run_test() {
	local name="$1"
	shift
	local extra_args=("$@")

	containers+=("$name")
	((total++))

	echo ""
	echo "==> Running test: $name"
	if docker run --name "$name" "${extra_args[@]}" "$image"; then
		echo "--- PASSED: $name"
	else
		echo "--- FAILED: $name"
		((failures++))
	fi
}

timestamp="$(date +%s)"

# Full Linux install
run_test "dotfiles-test-ubuntu-${timestamp}"

# Codespaces install
if [ "$run_codespaces" = "1" ]; then
	run_test "dotfiles-test-codespaces-${timestamp}" -e CODESPACES=true
fi

# --- Summary ----------------------------------------------------------------

echo ""
echo "========================================="
echo "  Results: $((total - failures))/$total passed"
echo "========================================="

exit "$failures"
