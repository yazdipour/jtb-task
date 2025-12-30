#!/bin/sh
# Create reproducible archive from Javadoc and release notes
set -eu

COMMIT_HASH="$1"
CACHE_DIR="${RELEASE_NOTES_CACHE_DIR:-release-notes}"
RELEASE_NOTES="$CACHE_DIR/$COMMIT_HASH.txt"
JAVADOC_DIR="target/reports/apidocs"
STAGING_DIR=".archive-staging"

if [ -f "$RELEASE_NOTES" ]; then
    TIMESTAMP=$(stat -c '%Y' "$RELEASE_NOTES")
    MTIME=$(date -u -d "@$TIMESTAMP" '+%Y-%m-%d %H:%M:%S')
else
    MTIME="1980-01-01 00:00:00"
fi

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR/docs/javadoc" "$STAGING_DIR/docs/release-notes"

cp -r "$JAVADOC_DIR/"* "$STAGING_DIR/docs/javadoc/"
[ -f "$RELEASE_NOTES" ] && cp "$RELEASE_NOTES" "$STAGING_DIR/docs/release-notes/RELEASE_NOTES.txt" || touch "$STAGING_DIR/docs/release-notes/RELEASE_NOTES.txt"

cd "$STAGING_DIR"
tar --sort=name --mtime="$MTIME" --owner=0 --group=0 --numeric-owner -czf ../docs.tar.gz docs/
cd ..

rm -rf "$STAGING_DIR"
sha256sum docs.tar.gz
