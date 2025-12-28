#!/bin/bash
# Simple test runner for release notes workflow

set -e

echo "🧪 Running workflow tests..."
echo ""

# Test 1: Success case
echo "Test 1: Download success"
MARKETING_URL="https://httpbin.org/html" ./scripts/fetch_release_notes.sh test-001
test -f release-notes/test-001.txt && echo "✓ Pass" || (echo "✗ Fail" && exit 1)
echo ""

# Test 2: Failure with no cache (creates placeholder)
echo "Test 2: Download failure without previous cache"
MARKETING_URL="https://httpbin.org/status/404" ./scripts/fetch_release_notes.sh test-002
grep -q "Release notes unavailable" release-notes/test-002.txt && echo "✓ Pass" || (echo "✗ Fail" && exit 1)
echo ""

# Test 3: Failure with fallback
echo "Test 3: Download failure with fallback to previous cache"
MARKETING_URL="https://httpbin.org/status/500" ./scripts/fetch_release_notes.sh test-003
test -f release-notes/test-003.txt && echo "✓ Pass" || (echo "✗ Fail" && exit 1)
echo ""

# Test 4: Full workflow
echo "Test 4: Complete archive workflow"
mvn -q javadoc:javadoc
./scripts/create_archive.sh test-001
test -f docs.tar.gz && echo "✓ Pass" || (echo "✗ Fail" && exit 1)
echo ""

# Test 5: Reproducibility
echo "Test 5: Reproducible builds"
HASH1=$(sha256sum docs.tar.gz | cut -d' ' -f1)
rm docs.tar.gz
./scripts/create_archive.sh test-001
HASH2=$(sha256sum docs.tar.gz | cut -d' ' -f1)
[ "$HASH1" = "$HASH2" ] && echo "✓ Pass - Builds are reproducible" || (echo "✗ Fail" && exit 1)
echo ""

echo "🎉 All tests passed!"
