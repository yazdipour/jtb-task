#!/bin/bash
# Test script to verify reproducible builds
# Order matches build pipeline: FetchReleaseNotes → DocsBuild
set -e

echo "=== Reproducible Build Test ==="

COMMIT=$(git rev-parse HEAD)
TIMESTAMP=$(git log -1 --format='%cI' HEAD)

cleanup() {
    rm -rf "$CACHE_DIR" docs1.tar.gz docs2.tar.gz release-notes.txt release-notes/
}
trap cleanup EXIT

echo "Commit: $COMMIT"
echo "Timestamp: $TIMESTAMP"
echo ""

# ============================================
# FetchReleaseNotes tests
# ============================================

# Test 1: MARKETING_URL validation
echo "--- Test 1: MARKETING_URL Required ---"

if docker run --rm -v "$PWD:/w" -w /w alpine:3.19 \
    sh -c "sh scripts/fetch_release_notes.sh test456 ''" 2>&1 | grep -q "marketing-url is required"; then
    echo "✅ PASS: MARKETING_URL validation works"
else
    echo "❌ FAIL: MARKETING_URL validation missing"
    exit 1
fi
echo ""

# Test 2: Fallback behavior - invalid URL should not fail
echo "--- Test 2: Fallback Behavior ---"

CACHE_DIR=$(mktemp -d)

echo "Testing with invalid URL..."
docker run --rm -v "$PWD:/w" -w /w \
    -e RELEASE_NOTES_CACHE_DIR=/cache \
    -v "$CACHE_DIR:/cache" \
    alpine:3.19 sh -c "apk add -q curl && sh scripts/fetch_release_notes.sh test123 'http://invalid.invalid/does-not-exist'" || true

if [ -f "$CACHE_DIR/test123.txt" ] && [ -f "release-notes.txt" ]; then
    echo "✅ PASS: Fallback file and output created"
else
    echo "❌ FAIL: Missing fallback file or output"
    exit 1
fi

rm -rf "$CACHE_DIR" release-notes.txt
echo ""

# ============================================
# DocsBuild tests
# ============================================

# Test 3: Commit timestamp script
echo "--- Test 3: Commit Timestamp Script ---"

OUTPUT=$(sh scripts/get_commit_timestamp.sh)
if echo "$OUTPUT" | grep -q "##teamcity\[setParameter"; then
    echo "✅ PASS: Timestamp script outputs TeamCity parameter"
else
    echo "❌ FAIL: Timestamp script output incorrect"
    exit 1
fi
echo ""

# Test 4: Reproducibility - same commit should produce identical archives
echo "--- Test 4: Reproducibility ---"

# Create fake release notes for reproducibility test
mkdir -p release-notes
echo "Test release notes" > release-notes/release-notes.txt

# Build 1
echo "Building archive #1..."
mvn -B -q clean javadoc:javadoc -Dproject.build.outputTimestamp="$TIMESTAMP"
docker run --rm -v "$PWD:/w" -w /w alpine:3.19 \
    sh -c "apk add -q tar && sh scripts/create_archive.sh '$COMMIT' '$TIMESTAMP'" > /dev/null
mv docs.tar.gz docs1.tar.gz

# Build 2
echo "Building archive #2..."
mvn -B -q clean javadoc:javadoc -Dproject.build.outputTimestamp="$TIMESTAMP"
docker run --rm -v "$PWD:/w" -w /w alpine:3.19 \
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

echo "=== All tests passed! ==="
