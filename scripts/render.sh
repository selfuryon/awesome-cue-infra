#!/usr/bin/env bash
# Renders one artifact (cluster/project) into a directory: manifests.yaml from
# CUE plus, for the flux artifact, the cluster's SOPS-encrypted secrets, which
# Flux decrypts in-cluster.
#
#   scripts/render.sh <cluster> <project> <out-dir>
set -euo pipefail

cluster=$1
project=$2
out=$3

mkdir -p "$out"
cue cmd dump -t cluster="$cluster" -t project="$project" >"$out/manifests.yaml"

secrets="clusters/$cluster/secrets"
if [[ "$project" == "flux" && -d "$secrets" ]]; then
  find "$secrets" -type f -name '*.sops.yaml' | sort | while read -r f; do
    cp "$f" "$out/secret-$(basename "$f")"
  done
fi
