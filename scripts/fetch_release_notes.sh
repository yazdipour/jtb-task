#!/bin/bash
# Fetch release notes, cache by commit hash, output timestamp for reproducibility
set -euo pipefail

COMMIT_HASH="$1"
CACHE_DIR="${RELEASE_NOTES_CACHE_DIR:-release-notes}"
CACHE_FILE="$CACHE_DIR/$COMMIT_HASH.txt"

mkdir -p "$CACHE_DIR"

# Use cached version if exists
if [ ! -f "$CACHE_FILE" ]; then
    # Try to download
    if ! curl -sSfL -m 10 "$MARKETING_URL" -o "$CACHE_FILE" 2>/dev/null; then
        # Fallback: copy most recent cache or create empty
        FALLBACK=$(find "$CACHE_DIR" -name "*.txt" -type f 2>/dev/null | head -1)
        if [ -n "$FALLBACK" ]; then
            cp "$FALLBACK" "$CACHE_FILE"
        else
            touch "$CACHE_FILE"
        fi
    fi
fi

# Output timestamp for reproducible builds (ISO 8601 format for Maven)
TIMESTAMP=$(stat -c '%Y' "$CACHE_FILE" 2>/dev/null || stat -f '%m' "$CACHE_FILE")
ISO_TIME=$(date -d "@$TIMESTAMP" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -r "$TIMESTAMP" -u '+%Y-%m-%dT%H:%M:%SZ')
echo "##teamcity[setParameter name='build.timestamp' value='$ISO_TIME']"
