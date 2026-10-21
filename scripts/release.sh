#!/usr/bin/env bash
# Points clusters at freshly published artifacts: merges publish results
# (JSON objects from scripts/publish.sh, one per file) into
# clusters/<cluster>/releases.json and regenerates the release layer.
#
#   scripts/release.sh <results-dir>
set -euo pipefail

results=$1

for f in "$results"/*.json; do
  cluster=$(jq -r .cluster "$f")
  file="clusters/$cluster/releases.json"
  jq --slurpfile r "$f" '.[$r[0].project] = {tag: $r[0].tag, digest: $r[0].digest}' "$file" >"$file.tmp"
  mv "$file.tmp" "$file"
done

cue cmd write-release
