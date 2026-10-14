#!/usr/bin/env bash
# Prunes old artifact versions from GHCR.
#
# Keeps every digest referenced by a clusters/*/releases.json (what clusters
# run, or can roll back to via revert) plus the newest $KEEP artifacts per
# package. Cosign signatures (sha256-<digest>.sig tags) live and die with
# their artifact; untagged leftovers are removed. Dry run unless DRY_RUN=0.
#
#   OWNER=selfuryon PREFIX=awesome-cue-infra KEEP=10 DRY_RUN=0 scripts/ghcr-cleanup.sh
set -euo pipefail

owner=${OWNER:-selfuryon}
prefix=${PREFIX:-awesome-cue-infra}
keep=${KEEP:-10}
dry_run=${DRY_RUN:-1}

pinned=$(jq -c '[.[].digest]' clusters/*/releases.json | jq -sc 'add // [] | unique')
echo "Pinned digests: $pinned"

gh api --paginate "/users/$owner/packages?package_type=container" -q ".[].name" |
  { grep "^$prefix/" || true; } |
  while read -r pkg; do
    enc=${pkg//\//%2F}
    # Versions come newest first.
    delete=$(gh api --paginate "/users/$owner/packages/container/$enc/versions" |
      jq -s -c --argjson keep "$keep" --argjson pinned "$pinned" '
        add
        | map({id, digest: .name, tags: .metadata.container.tags})
        | (map(select(.tags | any(startswith("sha256-") | not)))) as $artifacts
        | ([$artifacts[:$keep][].digest] + $pinned | unique) as $kept
        | ($kept | map("sha256-" + ltrimstr("sha256:") + ".sig")) as $keptSigs
        | map(select(
            (.digest | IN($kept[]) | not)
            and (.tags | any(IN($keptSigs[])) | not)
          ))
        | map({id, digest, tags})')

    count=$(jq 'length' <<<"$delete")
    echo "$pkg: $count version(s) to delete"
    jq -c '.[]' <<<"$delete" | while read -r v; do
      echo "  - $(jq -r '"\(.digest) \(.tags | join(","))"' <<<"$v")"
      if [[ "$dry_run" == "0" ]]; then
        gh api -X DELETE "/users/$owner/packages/container/$enc/versions/$(jq -r .id <<<"$v")"
      fi
    done
  done
