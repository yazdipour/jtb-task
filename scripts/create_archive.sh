#!/bin/bash
# Create reproducible archive from Javadoc and release notes
# Usage: ./create_archive.sh [commit-hash]

set -euo pipefail

COMMIT_HASH="${1:-unknown}"
JAVADOC_DIR="target/reports/apidocs"
STAGING_DIR=".archive-staging"
RELEASE_NOTES_DIR="${RELEASE_NOTES_CACHE_DIR:-release-notes}"

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

# Normalize timestamps and create archive
find "${STAGING_DIR}" -exec touch -t 198001010000 {} \;

cd "${STAGING_DIR}"
tar --sort=name \
    --mtime="1980-01-01 00:00:00" \
    --owner=0 --group=0 \
    --numeric-owner \
    -czf ../docs.tar.gz docs/
cd ..

# Clean up and show result
rm -rf "${STAGING_DIR}"
echo "Created docs.tar.gz"
sha256sum docs.tar.gz
