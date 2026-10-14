#!/usr/bin/env bash
# Publishes one artifact to GHCR and signs it with cosign (keyless).
#
# The tag is a hash of the rendered files, so unchanged content is never
# pushed twice and a release PR only appears when manifests really change.
# Prints {"cluster","project","tag","digest"} as JSON on stdout.
#
#   scripts/publish.sh <cluster> <project>
set -euo pipefail

cluster=$1
project=$2
registry=${REGISTRY:-ghcr.io/selfuryon/awesome-cue-infra}
image="$registry/$cluster-$project"

dist=$(mktemp -d)
trap 'rm -rf "$dist"' EXIT
scripts/render.sh "$cluster" "$project" "$dist"

tag=$(cd "$dist" && find . -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum | cut -c1-16)

if digest=$(oras resolve "$image:$tag" 2>/dev/null); then
  echo "Unchanged: $image:$tag@$digest" >&2
else
  echo "Pushing $image:$tag" >&2
  digest=$(cd "$dist" && oras push "$image:$tag" \
    --annotation "org.opencontainers.image.source=https://github.com/${GITHUB_REPOSITORY:-selfuryon/awesome-cue-infra}" \
    --annotation "org.opencontainers.image.revision=${GITHUB_SHA:-$(git rev-parse HEAD)}" \
    --annotation "org.opencontainers.image.created=$(date -u +%FT%TZ)" \
    --format go-template --template '{{.digest}}' .)
  # Legacy signature format: what Flux's OCIRepository cosign verification reads.
  cosign sign --yes \
    --new-bundle-format=false --use-signing-config=false \
    "$image@$digest" >&2
fi

jq -nc --arg cluster "$cluster" --arg project "$project" --arg tag "$tag" --arg digest "$digest" \
  '{cluster: $cluster, project: $project, tag: $tag, digest: $digest}'
