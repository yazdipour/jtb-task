#!/bin/bash
# Create reproducible archive from Javadoc and release notes
# Usage: ./create_archive.sh <commit-hash> [commit-timestamp]
#
# The archive uses the commit timestamp for reproducibility, ensuring
# the same commit always produces the same archive.

set -euo pipefail

COMMIT_HASH="${1:-unknown}"
JAVADOC_DIR="target/reports/apidocs"
STAGING_DIR=".archive-staging"
RELEASE_NOTES_DIR="${RELEASE_NOTES_CACHE_DIR:-release-notes}"

# Get commit timestamp - use provided value, or extract from git, or fallback to epoch
if [ -n "${2:-}" ]; then
    COMMIT_TIMESTAMP="$2"
elif command -v git &>/dev/null && git rev-parse --git-dir &>/dev/null; then
    # Get commit timestamp in format: YYYY-MM-DD HH:MM:SS
    COMMIT_TIMESTAMP=$(git log -1 --format='%ci' "${COMMIT_HASH}" 2>/dev/null | cut -d' ' -f1,2 || echo "1980-01-01 00:00:00")
else
    COMMIT_TIMESTAMP="1980-01-01 00:00:00"
fi

# Convert to touch format (YYYYMMDDHHMM)
TOUCH_TIMESTAMP=$(echo "${COMMIT_TIMESTAMP}" | sed 's/-//g; s/://g; s/ //g' | cut -c1-12)

echo "Using commit timestamp: ${COMMIT_TIMESTAMP}"

# Check Javadoc exists
if [ ! -d "${JAVADOC_DIR}" ]; then
    echo "ERROR: Javadoc not found. Run 'mvn javadoc:javadoc' first"
    exit 1
fi

# Prepare staging
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}/docs/javadoc"
mkdir -p "${STAGING_DIR}/docs/release-notes"

# Copy files
cp -r "${JAVADOC_DIR}/"* "${STAGING_DIR}/docs/javadoc/"

if [ -f "${RELEASE_NOTES_DIR}/${COMMIT_HASH}.txt" ]; then
    cp "${RELEASE_NOTES_DIR}/${COMMIT_HASH}.txt" "${STAGING_DIR}/docs/release-notes/RELEASE_NOTES.txt"
else
    touch "${STAGING_DIR}/docs/release-notes/RELEASE_NOTES.txt"
fi

# Normalize timestamps using commit time
find "${STAGING_DIR}" -exec touch -t "${TOUCH_TIMESTAMP}" {} \;

cd "${STAGING_DIR}"
tar --sort=name \
    --mtime="${COMMIT_TIMESTAMP}" \
    --owner=0 --group=0 \
    --numeric-owner \
    -czf ../docs.tar.gz docs/
cd ..

# Clean up and show result
rm -rf "${STAGING_DIR}"
echo "Created docs.tar.gz"
sha256sum docs.tar.gz
