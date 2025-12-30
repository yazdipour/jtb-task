#!/bin/bash
# Extract commit timestamp and export to TeamCity
set -euo pipefail

COMMIT_TS=$(git log -1 --format='%ci' HEAD 2>/dev/null | cut -d' ' -f1,2 || echo "1980-01-01 00:00:00")
echo "##teamcity[setParameter name='commit.timestamp' value='$COMMIT_TS']"
