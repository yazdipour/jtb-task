#!/bin/bash
# Run command in build container with workspace and cache mounted
set -euo pipefail

IMAGE="$1"
shift

CACHE_DIR="/opt/buildagent/cache/release-notes"
mkdir -p "$CACHE_DIR"

docker run --rm \
    -v "${TEAMCITY_BUILD_CHECKOUTDIR:-.}:/workspace" \
    -v "$CACHE_DIR:/cache" \
    -w /workspace \
    -e RELEASE_NOTES_CACHE_DIR=/cache \
    -e "MARKETING_URL=${MARKETING_URL:-}" \
    "$IMAGE" "$@"
