#!/bin/bash
#
# Walk current dir and grep all orion-res.access.json files looking
# for high latency values.

set -eo pipefail

find_high_latency() {
  files=$(find . -name orion-res.access.json)
  for f in $files
  do
    echo "$f"
    jq ". | select(.latency|tonumber>"$latency")" "$f"
  done
}

if [ "$#" -ne 1 ]; then
  echo "usage: $0 latency" >&2
  exit 1
fi

latency=$1
find_high_latency