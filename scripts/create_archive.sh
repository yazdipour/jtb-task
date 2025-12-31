#!/bin/sh
# Create reproducible archive from Javadoc and release notes
set -eu

COMMIT_HASH="$1"
TIMESTAMP="$2"
RELEASE_NOTES_FILE="${3:-release-notes/release-notes.txt}"
JAVADOC_DIR="target/reports/apidocs"
STAGING_DIR=".archive-staging"

# Convert ISO 8601 to tar-compatible format
MTIME=$(echo "$TIMESTAMP" | sed 's/T/ /; s/+.*//')

echo "Using timestamp: $MTIME"

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR/docs/javadoc" "$STAGING_DIR/docs/release-notes"

cp -r "$JAVADOC_DIR/"* "$STAGING_DIR/docs/javadoc/"
[ -f "$RELEASE_NOTES_FILE" ] && cp "$RELEASE_NOTES_FILE" "$STAGING_DIR/docs/release-notes/RELEASE_NOTES.txt" || touch "$STAGING_DIR/docs/release-notes/RELEASE_NOTES.txt"

cd "$STAGING_DIR"
tar --sort=name --mtime="$MTIME" --owner=0 --group=0 --numeric-owner -czf ../docs.tar.gz docs/
cd ..

rm -rf "$STAGING_DIR"
sha256sum docs.tar.gz
