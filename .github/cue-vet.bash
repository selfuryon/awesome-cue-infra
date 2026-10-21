#!/bin/bash
set -euo pipefail

# Vets every CUE package in the repo, one cue process per package in parallel.

echo "### Running cue vet on all packages..."

pkgs=$(
  for dir in $(find . -name "*.cue" -not -path "*/cue.mod/*" | sed 's|/[^/]*$||' | sort -u); do
    # The root package only holds ext_tool.cue, exercised by `cue cmd`.
    [[ "$dir" == "." ]] && continue
    for pkg in $(grep -h "^package " "$dir"/*.cue 2>/dev/null | awk '{print $2}' | sort -u); do
      echo "$dir:$pkg"
    done
  done
)

echo "$pkgs" | xargs -P "$(getconf _NPROCESSORS_ONLN)" -n 1 cue vet -c=false

echo "Vet checks passed"
