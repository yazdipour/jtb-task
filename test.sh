#!/bin/bash
# Simple test runner for release notes workflow (runs in an isolated temp dir)

set -euo pipefail

fail() {
	echo "✗ FAIL: $1"
	exit 1
}

pass() {
	echo "✓ Pass"
}

echo "🧪 Running workflow tests..."

ROOT_DIR="$(pwd)"
WORK_DIR="$(mktemp -d)"
cleanup() {
	rm -rf "${WORK_DIR}" 2>/dev/null || true
}
trap cleanup EXIT

mkdir -p "${WORK_DIR}/repo"
cp -R "${ROOT_DIR}/pom.xml" "${ROOT_DIR}/src" "${ROOT_DIR}/scripts" "${WORK_DIR}/repo/"

cd "${WORK_DIR}/repo"

echo ""
echo "Test 1: Failure without previous successful cache creates placeholder"
MARKETING_URL="https://httpbin.org/status/404" ./scripts/fetch_release_notes.sh no-cache-failure
grep -q "^# Release notes unavailable for commit" release-notes/no-cache-failure.txt || fail "expected placeholder"
pass

echo ""
echo "Test 2: Download success"
MARKETING_URL="https://httpbin.org/bytes/64?seed=1" ./scripts/fetch_release_notes.sh test-001
[ -f release-notes/test-001.txt ] || fail "cache file not created"
[ -s release-notes/test-001.txt ] || fail "cache file is empty"
pass

echo ""
echo "Test 3 (Step B): Cache hit uses cached file (no refetch)"
# First run uses a changing endpoint; the file should stay identical on cache hit even if the URL would return different content.
OUT1=$(MARKETING_URL="https://httpbin.org/uuid" ./scripts/fetch_release_notes.sh cache-hit-commit 2>&1)
echo "${OUT1}" | grep -q "downloaded and cached" || fail "expected initial download"
HASH_A=$(sha256sum release-notes/cache-hit-commit.txt | cut -d' ' -f1)

OUT2=$(MARKETING_URL="https://httpbin.org/uuid" ./scripts/fetch_release_notes.sh cache-hit-commit 2>&1)
echo "${OUT2}" | grep -q "Using cached release notes" || fail "expected cache hit message"
HASH_B=$(sha256sum release-notes/cache-hit-commit.txt | cut -d' ' -f1)

[ "${HASH_A}" = "${HASH_B}" ] || fail "cache-hit content changed (refetch happened)"
pass

echo ""
echo "Test 4: Failure uses previous successful cache as fallback"
MARKETING_URL="https://httpbin.org/bytes/64?seed=2" ./scripts/fetch_release_notes.sh good-cache
[ -f release-notes/good-cache.txt ] || fail "good-cache missing"

MARKETING_URL="https://httpbin.org/status/500" ./scripts/fetch_release_notes.sh fallback-cache
[ -f release-notes/fallback-cache.txt ] || fail "fallback-cache missing"

diff -q release-notes/good-cache.txt release-notes/fallback-cache.txt >/dev/null || fail "fallback did not reuse last successful cache"
pass

echo ""
echo "Test 5: Complete archive workflow"
mvn -q javadoc:javadoc
./scripts/create_archive.sh test-001
[ -f docs.tar.gz ] || fail "docs.tar.gz not created"
pass

echo ""
echo "Test 6: Reproducible archive checksum"
HASH1=$(sha256sum docs.tar.gz | cut -d' ' -f1)
rm docs.tar.gz
./scripts/create_archive.sh test-001
HASH2=$(sha256sum docs.tar.gz | cut -d' ' -f1)

[ "${HASH1}" = "${HASH2}" ] || fail "archive is not reproducible"
pass

echo ""
echo "🎉 All tests passed!"
