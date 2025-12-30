#!/bin/bash
# Build Docker image and generate Javadoc
set -euo pipefail

IMAGE="$1"

docker build --pull -t "$IMAGE" -f Dockerfile .
docker run --rm \
    -v "${TEAMCITY_BUILD_CHECKOUTDIR:-.}:/workspace" \
    -w /workspace \
    "$IMAGE" \
    mvn -B -q clean javadoc:javadoc
