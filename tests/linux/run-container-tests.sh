#!/usr/bin/env bash
# Run dotfiles install inside containers and verify the result.
# Uses podman if available, falls back to docker.
#
# Usage:
#   bash tests/linux/run-container-tests.sh [OPTIONS] [TEST...]
#
# Tests: full, codespaces
#   If none specified, runs all.
#
# Options:
#   --no-cleanup    Keep containers alive after tests (for debugging)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cleanup=1
tests=()
containers=()

# --- Detect container runtime ------------------------------------------------

if command -v podman >/dev/null 2>&1; then
	RUNTIME=podman
elif command -v docker >/dev/null 2>&1; then
	RUNTIME=docker
else
	echo "Error: neither podman nor docker found on PATH" >&2
	exit 1
fi

# --- Parse arguments --------------------------------------------------------

while [[ $# -gt 0 ]]; do
	case "$1" in
		--no-cleanup)
			cleanup=0
			shift
			;;
		full|codespaces)
			tests+=("$1")
			shift
			;;
		*)
			echo "Unknown option: $1" >&2
			echo "Usage: $0 [--no-cleanup] [full] [codespaces]" >&2
			exit 1
			;;
	esac
done

# Default to all tests if none specified
if [ ${#tests[@]} -eq 0 ]; then
	tests=(full codespaces)
fi

# --- Cleanup trap -----------------------------------------------------------

# shellcheck disable=SC2329
do_cleanup() {
	if [ "$cleanup" = "1" ]; then
		echo ""
		echo "==> Cleaning up containers"
		for name in "${containers[@]}"; do
			if $RUNTIME rm -f "$name" >/dev/null 2>&1; then
				echo "    removed $name"
			fi
		done
	else
		echo ""
		echo "==> Containers kept (--no-cleanup). To debug or clean up:"
		for name in "${containers[@]}"; do
			echo "    $RUNTIME exec -it $name bash"
			echo "    $RUNTIME rm -f $name"
		done
	fi
}
trap do_cleanup EXIT

# --- Build ------------------------------------------------------------------

image="dotfiles-test:ubuntu"
echo "==> Building image: $image (using $RUNTIME)"
$RUNTIME build -f "$REPO_DIR/tests/linux/Containerfile.ubuntu" -t "$image" "$REPO_DIR"

# --- Run tests --------------------------------------------------------------

total=0
failures=0

run_test() {
	local name="$1"
	shift
	local extra_args=("$@")

	containers+=("$name")
	total=$((total + 1))

	echo ""
	echo "==> Running test: $name"
	if $RUNTIME run --name "$name" "${extra_args[@]}" "$image"; then
		echo "--- PASSED: $name"
	else
		echo "--- FAILED: $name"
		failures=$((failures + 1))
	fi
}

timestamp="$(date +%s)"

for test in "${tests[@]}"; do
	case "$test" in
		full)
			run_test "dotfiles-test-full-${timestamp}"
			;;
		codespaces)
			run_test "dotfiles-test-codespaces-${timestamp}" -e CODESPACES=true
			;;
	esac
done

# --- Summary ----------------------------------------------------------------

echo ""
echo "========================================="
echo "  Results: $((total - failures))/$total passed"
echo "========================================="

exit "$failures"
