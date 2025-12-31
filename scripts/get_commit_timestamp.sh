#!/bin/sh
# Get commit timestamp and output as TeamCity parameter
set -eu

TS=$(git log -1 --format='%cI' HEAD)
echo "##teamcity[setParameter name='build.timestamp' value='$TS']"
