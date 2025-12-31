#!/bin/bash
# Test script to verify reproducible builds
set -e

echo "=== Reproducible Build Test ==="

COMMIT=$(git rev-parse HEAD)
TIMESTAMP=$(git log -1 --format='%cI' HEAD)
CACHE_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$CACHE_DIR" docs1.tar.gz docs2.tar.gz
}
trap cleanup EXIT

echo "Commit: $COMMIT"
echo "Timestamp: $TIMESTAMP"
echo ""

# Test 1: Reproducibility - same commit should produce identical archives
echo "--- Test 1: Reproducibility ---"

# Build 1
echo "Building archive #1..."
mvn -B -q clean javadoc:javadoc -Dproject.build.outputTimestamp="$TIMESTAMP"
docker run --rm -v "$PWD:/w" -w /w -e RELEASE_NOTES_CACHE_DIR="$CACHE_DIR" alpine:3.19 \
    sh -c "apk add -q tar && sh scripts/create_archive.sh '$COMMIT' '$TIMESTAMP'" > /dev/null
mv docs.tar.gz docs1.tar.gz

# Build 2
echo "Building archive #2..."
mvn -B -q clean javadoc:javadoc -Dproject.build.outputTimestamp="$TIMESTAMP"
docker run --rm -v "$PWD:/w" -w /w -e RELEASE_NOTES_CACHE_DIR="$CACHE_DIR" alpine:3.19 \
    sh -c "apk add -q tar && sh scripts/create_archive.sh '$COMMIT' '$TIMESTAMP'" > /dev/null
mv docs.tar.gz docs2.tar.gz

HASH1=$(sha256sum docs1.tar.gz | cut -d' ' -f1)
HASH2=$(sha256sum docs2.tar.gz | cut -d' ' -f1)

echo "Archive #1: $HASH1"
echo "Archive #2: $HASH2"

if [ "$HASH1" = "$HASH2" ]; then
    echo "✅ PASS: Archives are identical"
else
    echo "❌ FAIL: Archives differ!"
    exit 1
fi
echo ""

# Test 2: Fallback behavior - invalid URL should not fail
echo "--- Test 2: Fallback Behavior ---"

FALLBACK_CACHE=$(mktemp -d)
export MARKETING_URL="http://invalid.invalid/does-not-exist"
export RELEASE_NOTES_CACHE_DIR="$FALLBACK_CACHE"

echo "Testing with invalid URL: $MARKETING_URL"
docker run --rm -v "$PWD:/w" -w /w \
    -e MARKETING_URL="$MARKETING_URL" \
    -e RELEASE_NOTES_CACHE_DIR=/cache \
    -v "$FALLBACK_CACHE:/cache" \
    alpine:3.19 sh -c "apk add -q curl && sh scripts/fetch_release_notes.sh test123" || true

if [ -f "$FALLBACK_CACHE/test123.txt" ]; then
    echo "✅ PASS: Fallback file created"
else
    echo "❌ FAIL: No fallback file created"
    rm -rf "$FALLBACK_CACHE"
    exit 1
fi

rm -rf "$FALLBACK_CACHE"
echo ""

# Test 3: MARKETING_URL validation
echo "--- Test 3: MARKETING_URL Required ---"

if docker run --rm -v "$PWD:/w" -w /w alpine:3.19 \
    sh -c "sh scripts/fetch_release_notes.sh test456" 2>&1 | grep -q "MARKETING_URL is required"; then
    echo "✅ PASS: MARKETING_URL validation works"
else
    echo "❌ FAIL: MARKETING_URL validation missing"
    exit 1
fi
echo ""

echo "=== All tests passed! ==="
