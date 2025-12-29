#!/bin/bash
# Create reproducible archive from Javadoc and release notes
# Usage: ./create_archive.sh <commit-hash> <commit-timestamp>
#
# Arguments:
#   commit-hash:      Git commit hash for release notes lookup
#   commit-timestamp: Timestamp in 'YYYY-MM-DD HH:MM:SS' format (from TeamCity)
#
# The archive uses the commit timestamp for reproducibility, ensuring
# the same commit always produces the same archive.

set -euo pipefail

COMMIT_HASH="${1:?Usage: $0 <commit-hash> <commit-timestamp>}"
COMMIT_TIMESTAMP="${2:?Commit timestamp is required (format: YYYY-MM-DD HH:MM:SS)}"
JAVADOC_DIR="target/reports/apidocs"
STAGING_DIR=".archive-staging"
RELEASE_NOTES_DIR="${RELEASE_NOTES_CACHE_DIR:-release-notes}"

# Validate and normalize timestamp format (expected: YYYY-MM-DD HH:MM:SS)
# This ensures consistent archive timestamps regardless of input variations
validate_timestamp() {
    local ts="$1"
    # Check format matches YYYY-MM-DD HH:MM:SS (with optional timezone suffix)
    if [[ ! "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
        echo "ERROR: Invalid timestamp format: '$ts'"
        echo "Expected format: YYYY-MM-DD HH:MM:SS"
        exit 1
    fi
    # Return normalized timestamp (strip timezone if present, keep first 19 chars)
    echo "${ts:0:19}"
}

COMMIT_TIMESTAMP=$(validate_timestamp "${COMMIT_TIMESTAMP}")

# Convert to touch format (YYYYMMDDHHMM.SS)
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
