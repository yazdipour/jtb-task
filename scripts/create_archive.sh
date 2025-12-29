#!/bin/bash
# Create reproducible archive from Javadoc and release notes
# Usage: ./create_archive.sh [commit-hash]
#
# This script creates a byte-for-byte reproducible tar.gz archive containing
# Javadoc and release notes. Reproducibility is achieved by:
# - Using fixed timestamps (1980-01-01) for all files
# - Sorting files alphabetically in the archive
# - Using fixed owner/group IDs
# - Using deterministic compression settings
#
# Exit codes:
#   0 - Success
#   1 - Error (missing dependencies, invalid input, etc.)

set -euo pipefail

# Constants
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly FIXED_TIMESTAMP="198001010000"
readonly FIXED_MTIME="1980-01-01 00:00:00"
readonly ARCHIVE_NAME="docs.tar.gz"

# Defaults
readonly DEFAULT_JAVADOC_DIR="target/reports/apidocs"
readonly DEFAULT_STAGING_DIR=".archive-staging"
readonly DEFAULT_RELEASE_NOTES_DIR="release-notes"

# Show usage information
usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} [commit-hash]

Create a reproducible archive from Javadoc and release notes.

Arguments:
    commit-hash    Git commit hash (default: "unknown")

Environment variables:
    RELEASE_NOTES_CACHE_DIR    Directory containing cached release notes
                               (default: ${DEFAULT_RELEASE_NOTES_DIR})

Examples:
    ${SCRIPT_NAME} abc123
    RELEASE_NOTES_CACHE_DIR=/tmp/cache ${SCRIPT_NAME} abc123

Output:
    ${ARCHIVE_NAME} - Reproducible tar.gz archive

Requirements:
    - Maven Javadoc must be generated first (mvn javadoc:javadoc)
    - tar with --sort support (GNU tar 1.28+)
    - find command
    - touch command

EOF
}

# Print error message to stderr and exit
error_exit() {
    echo "ERROR: $*" >&2
    exit 1
}

# Print warning message to stderr
warn() {
    echo "WARNING: $*" >&2
}

# Print info message
info() {
    echo "INFO: $*"
}

# Validate required tools are available
check_requirements() {
    local missing_tools=()
    
    for tool in tar find touch sha256sum; do
        if ! command -v "${tool}" &> /dev/null; then
            missing_tools+=("${tool}")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        error_exit "Missing required tools: ${missing_tools[*]}"
    fi
    
    # Check if tar supports --sort option (GNU tar 1.28+)
    if ! tar --sort=name --help &> /dev/null; then
        error_exit "GNU tar with --sort support is required (version 1.28+)"
    fi
}

# Validate that Javadoc has been generated
validate_javadoc() {
    local javadoc_dir="$1"
    
    if [[ ! -d "${javadoc_dir}" ]]; then
        error_exit "Javadoc directory not found: ${javadoc_dir}
Please run 'mvn javadoc:javadoc' first"
    fi
    
    # Check if directory contains files
    if [[ -z "$(find "${javadoc_dir}" -type f -print -quit 2>/dev/null)" ]]; then
        error_exit "Javadoc directory is empty: ${javadoc_dir}"
    fi
}

# Prepare staging directory with all files
prepare_staging_directory() {
    local javadoc_dir="$1"
    local staging_dir="$2"
    local release_notes_dir="$3"
    local commit_hash="$4"
    
    info "Preparing staging directory: ${staging_dir}"
    
    # Clean up any existing staging directory
    if [[ -d "${staging_dir}" ]]; then
        rm -rf "${staging_dir}"
    fi
    
    # Create directory structure
    mkdir -p "${staging_dir}/docs/javadoc"
    mkdir -p "${staging_dir}/docs/release-notes"
    
    # Copy Javadoc files
    info "Copying Javadoc files..."
    cp -r "${javadoc_dir}/"* "${staging_dir}/docs/javadoc/" || \
        error_exit "Failed to copy Javadoc files"
    
    # Copy or create release notes
    local release_notes_file="${release_notes_dir}/${commit_hash}.txt"
    if [[ -f "${release_notes_file}" ]]; then
        info "Adding release notes from: ${release_notes_file}"
        cp "${release_notes_file}" "${staging_dir}/docs/release-notes/RELEASE_NOTES.txt"
    else
        warn "Release notes not found for commit ${commit_hash}, creating empty file"
        touch "${staging_dir}/docs/release-notes/RELEASE_NOTES.txt"
    fi
}

# Normalize timestamps for reproducibility
normalize_timestamps() {
    local staging_dir="$1"
    
    info "Normalizing timestamps to ${FIXED_MTIME} for reproducibility..."
    
    # Set modification time for all files and directories
    find "${staging_dir}" -exec touch -t "${FIXED_TIMESTAMP}" {} + || \
        error_exit "Failed to normalize timestamps"
}

# Create reproducible tar.gz archive
create_archive() {
    local staging_dir="$1"
    local archive_name="$2"
    
    info "Creating reproducible archive: ${archive_name}"
    
    # Change to staging directory to avoid including the staging path in archive
    cd "${staging_dir}" || error_exit "Failed to change to staging directory"
    
    # Create archive with reproducible settings
    # --sort=name: Sort files alphabetically
    # --mtime: Set modification time for reproducibility
    # --owner=0 --group=0: Use root user/group
    # --numeric-owner: Use numeric IDs instead of names
    # -czf: Create gzip compressed tar file
    tar --sort=name \
        --mtime="${FIXED_MTIME}" \
        --owner=0 --group=0 \
        --numeric-owner \
        -czf "../${archive_name}" docs/ || error_exit "Failed to create archive"
    
    cd - > /dev/null || error_exit "Failed to return to original directory"
}

# Clean up staging directory
cleanup_staging() {
    local staging_dir="$1"
    
    if [[ -d "${staging_dir}" ]]; then
        info "Cleaning up staging directory..."
        rm -rf "${staging_dir}"
    fi
}

# Verify and display archive information
verify_archive() {
    local archive_name="$1"
    
    if [[ ! -f "${archive_name}" ]]; then
        error_exit "Archive was not created: ${archive_name}"
    fi
    
    local file_size
    file_size=$(wc -c < "${archive_name}")
    
    local checksum
    checksum=$(sha256sum "${archive_name}" | cut -d' ' -f1)
    
    echo ""
    echo "=============================================="
    echo "Archive Created Successfully"
    echo "=============================================="
    echo "File:     ${archive_name}"
    echo "Size:     ${file_size} bytes"
    echo "SHA256:   ${checksum}"
    echo ""
    echo "To verify reproducibility:"
    echo "  1. Run this build again with the same commit hash"
    echo "  2. Compare the SHA256 checksums"
    echo "  3. They should be identical"
    echo "=============================================="
}

# Main execution
main() {
    # Parse arguments
    local commit_hash="${1:-unknown}"
    
    # Set defaults for configurable paths
    local javadoc_dir="${JAVADOC_DIR:-${DEFAULT_JAVADOC_DIR}}"
    local staging_dir="${STAGING_DIR:-${DEFAULT_STAGING_DIR}}"
    local release_notes_dir="${RELEASE_NOTES_CACHE_DIR:-${DEFAULT_RELEASE_NOTES_DIR}}"
    
    # Check requirements
    check_requirements
    
    # Validate Javadoc exists
    validate_javadoc "${javadoc_dir}"
    
    # Prepare staging directory
    prepare_staging_directory "${javadoc_dir}" "${staging_dir}" "${release_notes_dir}" "${commit_hash}"
    
    # Normalize timestamps
    normalize_timestamps "${staging_dir}"
    
    # Create archive
    create_archive "${staging_dir}" "${ARCHIVE_NAME}"
    
    # Clean up
    cleanup_staging "${staging_dir}"
    
    # Verify and display results
    verify_archive "${ARCHIVE_NAME}"
}

# Run main function
main "$@"
