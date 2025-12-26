#!/bin/bash
# fetch_release_notes.sh
# Downloads release notes from the marketing website with graceful failure handling.
# 
# Usage: ./fetch_release_notes.sh <commit-hash>
#
# Behavior:
#   1. If release-notes/{commit-hash}.txt exists, reuse it (snapshot)
#   2. If marketing site is available, download and cache the content
#   3. If download fails, create an empty placeholder file
#   4. NEVER fail the build due to network errors
#
# Environment Variables:
#   MARKETING_URL - URL to fetch release notes from (default: https://example.com)

set -euo pipefail

# Configuration
COMMIT_HASH="${1:-unknown}"
MARKETING_URL="${MARKETING_URL:-https://example.com}"
RELEASE_NOTES_DIR="release-notes"
CACHE_FILE="${RELEASE_NOTES_DIR}/${COMMIT_HASH}.txt"
TIMEOUT_SECONDS=10
MAX_RETRIES=2

# Ensure release-notes directory exists
mkdir -p "${RELEASE_NOTES_DIR}"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Function to download release notes with retries
download_release_notes() {
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        log "Attempting to download release notes (attempt $((retry_count + 1))/${MAX_RETRIES})..."
        
        # Use curl with timeout and fail silently on error
        if curl --silent \
                --fail \
                --location \
                --max-time "${TIMEOUT_SECONDS}" \
                --retry 0 \
                --output "${CACHE_FILE}.tmp" \
                "${MARKETING_URL}" 2>/dev/null; then
            
            # Verify we got some content
            if [ -s "${CACHE_FILE}.tmp" ]; then
                mv "${CACHE_FILE}.tmp" "${CACHE_FILE}"
                log "Successfully downloaded release notes from ${MARKETING_URL}"
                return 0
            else
                log "Downloaded file is empty, treating as failure"
                rm -f "${CACHE_FILE}.tmp"
            fi
        fi
        
        retry_count=$((retry_count + 1))
        
        if [ $retry_count -lt $MAX_RETRIES ]; then
            log "Download failed, retrying in 2 seconds..."
            sleep 2
        fi
    done
    
    return 1
}

# Main logic
log "Fetching release notes for commit: ${COMMIT_HASH}"
log "Marketing URL: ${MARKETING_URL}"

# Check if cached release notes already exist
if [ -f "${CACHE_FILE}" ]; then
    log "Using cached release notes: ${CACHE_FILE}"
    log "Cache file size: $(wc -c < "${CACHE_FILE}") bytes"
    exit 0
fi

# Attempt to download release notes
if download_release_notes; then
    log "Release notes cached successfully"
else
    # Create empty placeholder file on failure
    log "WARNING: Failed to download release notes from ${MARKETING_URL}"
    log "Creating empty placeholder file to allow build to continue"
    
    # Create empty file with a header comment
    cat > "${CACHE_FILE}" << EOF
# Release Notes Unavailable
# 
# The marketing website was unavailable when this build ran.
# Commit: ${COMMIT_HASH}
# Attempted URL: ${MARKETING_URL}
# Timestamp: $(date -u '+%Y-%m-%dT%H:%M:%SZ')
#
# This empty placeholder ensures build reproducibility.
EOF
    
    log "Created placeholder: ${CACHE_FILE}"
fi

# Verify the file exists (should always be true at this point)
if [ -f "${CACHE_FILE}" ]; then
    log "Release notes file ready: ${CACHE_FILE}"
    log "File size: $(wc -c < "${CACHE_FILE}") bytes"
    exit 0
else
    log "ERROR: Failed to create release notes file"
    exit 1
fi
