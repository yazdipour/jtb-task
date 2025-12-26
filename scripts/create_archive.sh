#!/bin/bash
# create_archive.sh
# Creates a byte-for-byte reproducible tar.gz archive containing Javadoc and release notes.
#
# Usage: ./create_archive.sh [commit-hash]
#
# Reproducibility guarantees:
#   - Fixed timestamp: 1980-01-01 00:00:00 UTC
#   - Sorted file order: Files are added alphabetically
#   - Fixed ownership: All files owned by root:root (0:0)
#   - Deterministic compression: Using gzip with fixed settings
#
# Output: docs.tar.gz in the current directory

set -euo pipefail

# Configuration
COMMIT_HASH="${1:-unknown}"
OUTPUT_FILE="docs.tar.gz"
JAVADOC_DIR="target/reports/apidocs"
RELEASE_NOTES_DIR="release-notes"
STAGING_DIR=".archive-staging"

# Fixed timestamp for reproducibility (Unix epoch: 315532800 = 1980-01-01 00:00:00 UTC)
FIXED_TIMESTAMP="1980-01-01 00:00:00"
SOURCE_DATE_EPOCH=315532800

# Export for tools that respect it
export SOURCE_DATE_EPOCH

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Function to clean up staging directory
cleanup() {
    if [ -d "${STAGING_DIR}" ]; then
        rm -rf "${STAGING_DIR}"
    fi
}

# Set up cleanup trap
trap cleanup EXIT

# Validate inputs
log "Creating reproducible archive for commit: ${COMMIT_HASH}"

if [ ! -d "${JAVADOC_DIR}" ]; then
    log "ERROR: Javadoc directory not found: ${JAVADOC_DIR}"
    log "Please run 'mvn javadoc:javadoc' first"
    exit 1
fi

# Prepare staging directory
log "Preparing staging directory..."
cleanup
mkdir -p "${STAGING_DIR}/docs/javadoc"
mkdir -p "${STAGING_DIR}/docs/release-notes"

# Copy Javadoc files
log "Copying Javadoc files..."
cp -r "${JAVADOC_DIR}/"* "${STAGING_DIR}/docs/javadoc/"

# Copy release notes for this commit (if exists)
RELEASE_NOTES_FILE="${RELEASE_NOTES_DIR}/${COMMIT_HASH}.txt"
if [ -f "${RELEASE_NOTES_FILE}" ]; then
    log "Including release notes: ${RELEASE_NOTES_FILE}"
    cp "${RELEASE_NOTES_FILE}" "${STAGING_DIR}/docs/release-notes/RELEASE_NOTES.txt"
else
    log "WARNING: No release notes found for commit ${COMMIT_HASH}"
    log "Creating empty placeholder..."
    touch "${STAGING_DIR}/docs/release-notes/RELEASE_NOTES.txt"
fi

# Create manifest file with build metadata
log "Creating build manifest..."
cat > "${STAGING_DIR}/docs/MANIFEST.txt" << EOF
Build Manifest
==============
Commit: ${COMMIT_HASH}
Build Timestamp: ${FIXED_TIMESTAMP} UTC
Archive Format: tar.gz (gzip compressed)

Contents:
- javadoc/: Generated API documentation
- release-notes/: Release notes from marketing website

Reproducibility:
- All file timestamps normalized to ${FIXED_TIMESTAMP}
- Files sorted alphabetically
- Owner/group set to root:root (0:0)
EOF

# Normalize timestamps on all files in staging directory
log "Normalizing file timestamps..."
find "${STAGING_DIR}" -type f -exec touch -d "${FIXED_TIMESTAMP}" {} \;
find "${STAGING_DIR}" -type d -exec touch -d "${FIXED_TIMESTAMP}" {} \;

# Create the reproducible archive
log "Creating reproducible archive: ${OUTPUT_FILE}"

# Change to staging directory and create archive
cd "${STAGING_DIR}"

# Use tar with reproducibility flags
# --sort=name: Deterministic file order
# --mtime: Fixed modification time
# --owner=0 --group=0: Fixed ownership
# --numeric-owner: Use numeric IDs (more portable)
# --format=gnu: Consistent tar format
# -c: Create archive
# -z: Gzip compression
# -f: Output file

# First, get sorted list of all files
find docs -type f -o -type d | sort > ../file-list.txt

# Create archive with explicit file list for deterministic ordering
tar --sort=name \
    --mtime="${FIXED_TIMESTAMP}" \
    --owner=0 \
    --group=0 \
    --numeric-owner \
    --format=gnu \
    --no-recursion \
    -czf "../${OUTPUT_FILE}" \
    -T ../file-list.txt

cd ..

# Clean up file list
rm -f file-list.txt

# Verify archive was created
if [ -f "${OUTPUT_FILE}" ]; then
    ARCHIVE_SIZE=$(wc -c < "${OUTPUT_FILE}")
    ARCHIVE_SHA256=$(sha256sum "${OUTPUT_FILE}" | cut -d' ' -f1)
    
    log "Archive created successfully!"
    log "  File: ${OUTPUT_FILE}"
    log "  Size: ${ARCHIVE_SIZE} bytes"
    log "  SHA256: ${ARCHIVE_SHA256}"
    
    # List archive contents for verification
    log "Archive contents:"
    tar -tzvf "${OUTPUT_FILE}" | head -20
    
    FILE_COUNT=$(tar -tzf "${OUTPUT_FILE}" | wc -l)
    log "Total files in archive: ${FILE_COUNT}"
else
    log "ERROR: Failed to create archive"
    exit 1
fi

log "Archive creation complete"
