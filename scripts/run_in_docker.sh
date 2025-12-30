#!/bin/bash
# Run command in Docker with workspace and cache mounted (minimal Alpine image)
set -euo pipefail

CACHE_DIR="/opt/buildagent/cache/release-notes"
mkdir -p "$CACHE_DIR"

docker run --rm \
    -v "${TEAMCITY_BUILD_CHECKOUTDIR:-.}:/workspace" \
    -v "$CACHE_DIR:/cache" \
    -w /workspace \
    -e RELEASE_NOTES_CACHE_DIR=/cache \
    -e "MARKETING_URL=${MARKETING_URL:-}" \
    alpine:3.19 \
    sh -c "apk add --no-cache -q bash curl tar && $*"
