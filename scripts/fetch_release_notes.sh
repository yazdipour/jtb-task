#!/bin/sh
# Fetch release notes and output to release-notes.txt
# Usage: ./fetch_release_notes.sh <commit-hash> <marketing-url>
set -eu

COMMIT_HASH="$1"
MARKETING_URL="$2"

[ -z "$COMMIT_HASH" ] && echo "Error: commit-hash is required" && exit 1
[ -z "$MARKETING_URL" ] && echo "Error: marketing-url is required" && exit 1

CACHE_DIR="${CACHE_DIR:-/cache}"
CACHE_FILE="$CACHE_DIR/release-notes.txt"

mkdir -p "$CACHE_DIR"

# Try to download release notes
if curl -sSfL -m 10 "$MARKETING_URL" -o release-notes.txt 2>/dev/null; then
    # Success - update cache
    cp release-notes.txt "$CACHE_FILE"
    echo "DOWNLOAD: $MARKETING_URL (cached)"
elif [ -f "$CACHE_FILE" ]; then
    # Download failed but cache exists - use it
    cp "$CACHE_FILE" release-notes.txt
    echo "CACHE HIT: using cached release notes"
else
    # No cache, no download - create placeholder
    echo "Release notes unavailable (build: $COMMIT_HASH)" > release-notes.txt
    echo "FALLBACK: placeholder (no cache, URL unavailable)"
fi
