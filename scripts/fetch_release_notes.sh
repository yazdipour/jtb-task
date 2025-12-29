#!/bin/bash
# Fetch release notes and cache them by commit hash
# Usage: ./fetch_release_notes.sh <commit-hash>
#
# This script downloads release notes from a marketing website and caches them
# by commit hash. It implements graceful failure handling to ensure builds
# never fail due to unreachable external dependencies.
#
# Exit codes:
#   0 - Success (cache hit, successful download, or fallback used)
#   1 - Invalid usage (missing required parameters)

set -euo pipefail

# Constants
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly CURL_TIMEOUT=10
readonly CURL_MAX_RETRIES=3

# Show usage information
usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} <commit-hash>

Fetch release notes from the marketing website and cache them by commit hash.

Arguments:
    commit-hash    Git commit hash to associate with these release notes

Environment variables:
    MARKETING_URL              URL to fetch release notes from (required)
    RELEASE_NOTES_CACHE_DIR    Directory to cache release notes (default: release-notes)

Examples:
    MARKETING_URL=https://example.com/releases.txt ${SCRIPT_NAME} abc123
    RELEASE_NOTES_CACHE_DIR=/tmp/cache ${SCRIPT_NAME} abc123

EOF
}

# Print error message to stderr
error() {
    echo "ERROR: $*" >&2
}

# Print warning message to stderr
warn() {
    echo "WARNING: $*" >&2
}

# Print info message
info() {
    echo "INFO: $*"
}

# Validate required parameters
validate_params() {
    if [[ -z "${COMMIT_HASH:-}" ]]; then
        error "Commit hash is required"
        usage
        exit 1
    fi
    
    if [[ -z "${MARKETING_URL:-}" ]]; then
        error "MARKETING_URL environment variable is required"
        usage
        exit 1
    fi
    
    # Validate commit hash format (basic check)
    if [[ ! "${COMMIT_HASH}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "Invalid commit hash format: ${COMMIT_HASH}"
        exit 1
    fi
}

# Download release notes with retry logic
download_with_retry() {
    local url="$1"
    local output_file="$2"
    local attempt=1
    
    while [[ ${attempt} -le ${CURL_MAX_RETRIES} ]]; do
        info "Download attempt ${attempt}/${CURL_MAX_RETRIES} from ${url}..."
        
        if curl -sS --fail -L -m "${CURL_TIMEOUT}" "${url}" -o "${output_file}" 2>/dev/null; then
            info "Download successful"
            return 0
        fi
        
        warn "Download attempt ${attempt} failed"
        ((attempt++))
        
        if [[ ${attempt} -le ${CURL_MAX_RETRIES} ]]; then
            sleep 2
        fi
    done
    
    return 1
}

# Find the most recent successful cache entry (excluding placeholders)
find_latest_cache() {
    local cache_dir="$1"
    local current_cache="$2"
    local latest_cache=""
    
    # Get list of cache files sorted by modification time (newest first)
    local candidates=()
    while IFS= read -r -d $'\0' file; do
        candidates+=("${file}")
    done < <(find "${cache_dir}" -maxdepth 1 -type f -name "*.txt" -print0 2>/dev/null | xargs -0 ls -1t 2>/dev/null || true)
    
    # Find first non-placeholder cache entry
    for candidate in "${candidates[@]}"; do
        # Skip current cache file
        if [[ "${candidate}" == "${current_cache}" ]]; then
            continue
        fi
        
        # Skip placeholder files (those starting with "# Release notes unavailable")
        if head -n 1 "${candidate}" 2>/dev/null | grep -q '^# Release notes unavailable for commit '; then
            continue
        fi
        
        # Skip empty files
        if [[ ! -s "${candidate}" ]]; then
            continue
        fi
        
        latest_cache="${candidate}"
        break
    done
    
    echo "${latest_cache}"
}

# Main execution
main() {
    # Parse arguments
    COMMIT_HASH="${1:-}"
    
    # Validate parameters
    validate_params
    
    # Set defaults for optional parameters
    CACHE_DIR="${RELEASE_NOTES_CACHE_DIR:-release-notes}"
    CACHE_FILE="${CACHE_DIR}/${COMMIT_HASH}.txt"
    
    # Create cache directory if it doesn't exist
    mkdir -p "${CACHE_DIR}"
    
    # Use cached version if available
    if [[ -f "${CACHE_FILE}" ]]; then
        info "Using cached release notes: ${CACHE_FILE}"
        exit 0
    fi
    
    # Try to download (write to temp file first to avoid partial files)
    info "Downloading release notes from ${MARKETING_URL}..."
    TMP_FILE="$(mktemp)"
    
    # Cleanup function for temporary files
    cleanup() {
        rm -f "${TMP_FILE}" 2>/dev/null || true
    }
    trap cleanup EXIT
    
    # Attempt download with retry
    if download_with_retry "${MARKETING_URL}" "${TMP_FILE}"; then
        mv "${TMP_FILE}" "${CACHE_FILE}"
        info "Release notes downloaded and cached successfully"
        exit 0
    fi
    
    warn "Download failed after ${CURL_MAX_RETRIES} attempts"
    
    # On failure, use the most recent successful cache as fallback
    LATEST_CACHE="$(find_latest_cache "${CACHE_DIR}" "${CACHE_FILE}")"
    
    if [[ -n "${LATEST_CACHE}" ]]; then
        info "Using most recent cached release notes as fallback: ${LATEST_CACHE}"
        cp "${LATEST_CACHE}" "${CACHE_FILE}"
    else
        warn "No previous successful cache found, creating placeholder"
        echo "# Release notes unavailable for commit ${COMMIT_HASH}" > "${CACHE_FILE}"
        echo "# The marketing website was not available when this build ran." >> "${CACHE_FILE}"
        echo "# This is a placeholder to ensure build reproducibility." >> "${CACHE_FILE}"
    fi
    
    # Always exit with success to not fail the build
    exit 0
}

# Run main function
main "$@"
