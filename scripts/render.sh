#!/usr/bin/env bash
# Renders one artifact (cluster/set) into a directory: manifests.yaml from CUE
# plus the set's SOPS-encrypted secrets (clusters/<cluster>/secrets/<set>/),
# which Flux decrypts in-cluster. Only Flux sets can carry secrets: Argo CD
# cannot decrypt SOPS.
#
#   scripts/render.sh <cluster> <set> <out-dir>
set -euo pipefail

cluster=$1
project=$2
out=$3

mkdir -p "$out"
cue cmd dump -t cluster="$cluster" -t project="$project" >"$out/manifests.yaml"

secrets="clusters/$cluster/secrets/$project"
if [[ -d "$secrets" ]]; then
  controller=$(cue cmd cluster-config -t cluster="$cluster" | jq -r --arg c "$cluster" --arg s "$project" '.[$c].sets[$s].controller')
  if [[ "$controller" != "flux" ]]; then
    echo "$secrets: secrets are only supported in Flux sets ($project is $controller)" >&2
    exit 1
  fi
  find "$secrets" -type f -name '*.sops.yaml' | sort | while read -r f; do
    cp "$f" "$out/secret-$(basename "$f")"
  done
fi
