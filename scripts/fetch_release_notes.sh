#!/bin/sh
# Fetch release notes and cache by commit hash
set -eu

[ -z "${MARKETING_URL:-}" ] && echo "Error: MARKETING_URL is required" && exit 1

COMMIT_HASH="$1"
CACHE_DIR="${RELEASE_NOTES_CACHE_DIR:-release-notes}"
CACHE_FILE="$CACHE_DIR/$COMMIT_HASH.txt"

mkdir -p "$CACHE_DIR"

if [ -f "$CACHE_FILE" ]; then
    echo "CACHE HIT: $CACHE_FILE"
elif curl -sSfL -m 10 "$MARKETING_URL" -o "$CACHE_FILE" 2>/dev/null; then
    echo "CACHE MISS: Downloading from $MARKETING_URL"
else
    FALLBACK=$(find "$CACHE_DIR" -name "*.txt" -type f 2>/dev/null | head -1)
    if [ -n "$FALLBACK" ]; then
        cp "$FALLBACK" "$CACHE_FILE"
        echo "CACHE MISS: Fallbacking to $FALLBACK"
    else
        touch "$CACHE_FILE"
        echo "CACHE MISS: Creating empty placeholder"
    fi
fi
