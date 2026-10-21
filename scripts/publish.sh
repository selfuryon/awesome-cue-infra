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

started=$(date -u +%FT%TZ)
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

  # SLSA provenance (v1) for the artifact, attested with the same identity.
  # Only in GitHub Actions, which is where the build parameters come from.
  if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    jq -n \
      --arg server "$GITHUB_SERVER_URL" --arg repo "$GITHUB_REPOSITORY" \
      --arg ref "$GITHUB_REF" --arg sha "$GITHUB_SHA" --arg event "$GITHUB_EVENT_NAME" \
      --arg repo_id "$GITHUB_REPOSITORY_ID" --arg owner_id "$GITHUB_REPOSITORY_OWNER_ID" \
      --arg run_id "$GITHUB_RUN_ID" --arg run_attempt "$GITHUB_RUN_ATTEMPT" \
      --arg cluster "$cluster" --arg project "$project" \
      --arg started "$started" --arg finished "$(date -u +%FT%TZ)" \
      '{
        buildDefinition: {
          buildType: "https://actions.github.io/buildtypes/workflow/v1",
          externalParameters: {
            workflow: {ref: $ref, repository: "\($server)/\($repo)", path: ".github/workflows/publish.yaml"},
            inputs: {cluster: $cluster, project: $project}
          },
          internalParameters: {
            github: {event_name: $event, repository_id: $repo_id, repository_owner_id: $owner_id, runner_environment: "github-hosted"}
          },
          resolvedDependencies: [{uri: "git+\($server)/\($repo)@\($ref)", digest: {gitCommit: $sha}}]
        },
        runDetails: {
          builder: {id: "\($server)/\($repo)/.github/workflows/publish.yaml@\($ref)"},
          metadata: {
            invocationId: "\($server)/\($repo)/actions/runs/\($run_id)/attempts/\($run_attempt)",
            startedOn: $started,
            finishedOn: $finished
          }
        }
      }' >"$dist.predicate.json"
    cosign attest --yes \
      --new-bundle-format=false --use-signing-config=false \
      --type slsaprovenance1 --predicate "$dist.predicate.json" \
      "$image@$digest" >&2
    rm -f "$dist.predicate.json"
  fi
fi

jq -nc --arg cluster "$cluster" --arg project "$project" --arg tag "$tag" --arg digest "$digest" \
  '{cluster: $cluster, project: $project, tag: $tag, digest: $digest}'
