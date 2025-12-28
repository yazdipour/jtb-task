#!/bin/bash
# Fetch release notes and cache them by commit hash
# Usage: ./fetch_release_notes.sh <commit-hash>

set -euo pipefail

COMMIT_HASH="${1:-unknown}"
MARKETING_URL="${MARKETING_URL:?MARKETING_URL is required}"
CACHE_DIR="${RELEASE_NOTES_CACHE_DIR:-release-notes}"
CACHE_FILE="${CACHE_DIR}/${COMMIT_HASH}.txt"

mkdir -p "${CACHE_DIR}"

# Use cached version if available
if [ -f "${CACHE_FILE}" ]; then
    echo "Using cached release notes: ${CACHE_FILE}"
    exit 0
fi

# Try to download (write to temp file first so we never leave partial files behind)
echo "Downloading release notes from ${MARKETING_URL}..."
TMP_FILE="$(mktemp)"

cleanup() {
    rm -f "${TMP_FILE}" 2>/dev/null || true
}
trap cleanup EXIT

if curl -sS --fail -L -m 10 "${MARKETING_URL}" -o "${TMP_FILE}" 2>/dev/null; then
    mv "${TMP_FILE}" "${CACHE_FILE}"
    echo "Release notes downloaded and cached"
    exit 0
fi

echo "WARNING: Download failed"

# On failure, use the most recent *successful* cache as fallback.
# (Exclude placeholder files to avoid copying a previous failure forward.)
LATEST_CACHE=""
mapfile -t CANDIDATES < <(ls -1t "${CACHE_DIR}"/*.txt 2>/dev/null || true)
for candidate in "${CANDIDATES[@]}"; do
    if [ "${candidate}" = "${CACHE_FILE}" ]; then
        continue
    fi

    if head -n 1 "${candidate}" 2>/dev/null | grep -q '^# Release notes unavailable for commit '; then
        continue
    fi

    if [ -s "${candidate}" ]; then
        LATEST_CACHE="${candidate}"
        break
    fi
done

if [ -n "${LATEST_CACHE}" ]; then
    echo "Using most recent cached release notes as fallback: ${LATEST_CACHE}"
    cp "${LATEST_CACHE}" "${CACHE_FILE}"
else
    echo "No previous successful cache found, creating placeholder"
    echo "# Release notes unavailable for commit ${COMMIT_HASH}" > "${CACHE_FILE}"
fi
