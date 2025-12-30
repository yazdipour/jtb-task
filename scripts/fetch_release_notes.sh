#!/bin/sh
# Fetch release notes, cache by commit hash, output timestamp for reproducibility
set -eu

COMMIT_HASH="$1"
CACHE_DIR="${RELEASE_NOTES_CACHE_DIR:-release-notes}"
CACHE_FILE="$CACHE_DIR/$COMMIT_HASH.txt"

mkdir -p "$CACHE_DIR"

if [ ! -f "$CACHE_FILE" ]; then
    if ! curl -sSfL -m 10 "$MARKETING_URL" -o "$CACHE_FILE" 2>/dev/null; then
        FALLBACK=$(find "$CACHE_DIR" -name "*.txt" -type f 2>/dev/null | head -1)
        [ -n "$FALLBACK" ] && cp "$FALLBACK" "$CACHE_FILE" || touch "$CACHE_FILE"
    fi
fi

# Output timestamp (ISO 8601 for Maven)
TIMESTAMP=$(stat -c '%Y' "$CACHE_FILE")
ISO_TIME=$(date -u -d "@$TIMESTAMP" '+%Y-%m-%dT%H:%M:%SZ')
echo "##teamcity[setParameter name='build.timestamp' value='$ISO_TIME']"
