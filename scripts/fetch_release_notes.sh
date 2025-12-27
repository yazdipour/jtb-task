#!/bin/bash
# Fetch release notes and cache them by commit hash
# Usage: ./fetch_release_notes.sh <commit-hash>

set -euo pipefail

COMMIT_HASH="${1:-unknown}"
MARKETING_URL="${MARKETING_URL:-https://example.com}"
CACHE_FILE="release-notes/${COMMIT_HASH}.txt"

mkdir -p release-notes

# Use cached version if available
if [ -f "${CACHE_FILE}" ]; then
    echo "Using cached release notes: ${CACHE_FILE}"
    exit 0
fi

# Try to download
echo "Downloading release notes from ${MARKETING_URL}..."
if curl -sSf -m 10 "${MARKETING_URL}" -o "${CACHE_FILE}" 2>/dev/null; then
    echo "Release notes downloaded and cached"
else
    # Create empty placeholder on failure
    echo "WARNING: Download failed, creating empty placeholder"
    echo "# Release notes unavailable for commit ${COMMIT_HASH}" > "${CACHE_FILE}"
fi
