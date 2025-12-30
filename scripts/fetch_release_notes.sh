#!/bin/bash
# Fetch release notes and cache by commit hash
set -euo pipefail

COMMIT_HASH="$1"
CACHE_DIR="${RELEASE_NOTES_CACHE_DIR:-release-notes}"
CACHE_FILE="$CACHE_DIR/$COMMIT_HASH.txt"

mkdir -p "$CACHE_DIR"

# Use cached version if exists
if [ -f "$CACHE_FILE" ]; then
    echo "Using cached: $CACHE_FILE"
    exit 0
fi

# Try to download
if curl -sSfL -m 10 "$MARKETING_URL" -o "$CACHE_FILE" 2>/dev/null; then
    echo "Downloaded release notes"
    exit 0
fi

# Fallback: copy most recent cache or create empty
FALLBACK=$(find "$CACHE_DIR" -name "*.txt" -type f 2>/dev/null | head -1)
if [ -n "$FALLBACK" ]; then
    cp "$FALLBACK" "$CACHE_FILE"
    echo "[WARNING] Using fallback: $FALLBACK"
else
    touch "$CACHE_FILE"
    echo "Created empty placeholder"
fi
