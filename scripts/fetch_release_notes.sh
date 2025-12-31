#!/bin/sh
# Fetch release notes and cache by commit hash
set -eu

[ -z "${MARKETING_URL:-}" ] && echo "Error: MARKETING_URL is required" && exit 1

COMMIT_HASH="$1"
CACHE_DIR="${RELEASE_NOTES_CACHE_DIR:-release-notes}"
CACHE_FILE="$CACHE_DIR/$COMMIT_HASH.txt"
FALLBACK_MARKER="$CACHE_FILE.fallback"

mkdir -p "$CACHE_DIR"

# If cached AND not a fallback, use it
if [ -f "$CACHE_FILE" ] && [ ! -f "$FALLBACK_MARKER" ]; then
    echo "CACHE HIT: $CACHE_FILE"
    exit 0
fi

# Try to download
if curl -sSfL -m 10 "$MARKETING_URL" -o "$CACHE_FILE" 2>/dev/null; then
    rm -f "$FALLBACK_MARKER"
    echo "DOWNLOAD: $MARKETING_URL"
    exit 0
fi

# Download failed - use fallback but mark it so we retry next time
FALLBACK=$(find "$CACHE_DIR" -name "*.txt" -type f 2>/dev/null | head -1)
if [ -n "$FALLBACK" ]; then
    cp "$FALLBACK" "$CACHE_FILE"
    touch "$FALLBACK_MARKER"
    echo "FALLBACK: $FALLBACK (will retry next build)"
else
    touch "$CACHE_FILE"
    touch "$FALLBACK_MARKER"
    echo "FALLBACK: empty placeholder (will retry next build)"
fi
