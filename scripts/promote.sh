#!/usr/bin/env bash
# Promotes component versions into a cluster's pins.json.
#
# The source is either `latest` (apps/registry/latest.json) or another
# cluster (the versions it currently resolves). Only components the target
# cluster already uses are touched; limit further with a comma-separated list.
#
#   scripts/promote.sh <to-cluster> <from: latest|cluster> [component,...]
set -euo pipefail

to=$1
from=$2
only=${3:-}

pins="clusters/$to/pins.json"
[[ -f "$pins" ]] || { echo "unknown cluster: $to" >&2; exit 1; }

if [[ "$from" == "latest" ]]; then
  source=$(jq -c '[.components[] | {(.name): .version}] | add' apps/registry/latest.json)
else
  source=$(cue cmd versions -t cluster="$from" | jq -c --arg c "$from" '.[$c]')
fi
target=$(cue cmd versions -t cluster="$to" | jq -c --arg c "$to" '.[$c] | keys')

jq --argjson source "$source" --argjson target "$target" --arg only "$only" '
  ($only | split(",") | map(select(length > 0))) as $names
  | reduce ($target[] | select(($names | length) == 0 or (. as $n | $names | index($n)))) as $n (.;
      if $source[$n] then .[$n] = $source[$n] else . end)
' "$pins" >"$pins.tmp"
mv "$pins.tmp" "$pins"

git --no-pager diff -- "$pins"
