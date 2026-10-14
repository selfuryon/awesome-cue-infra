---
name: crd-generation
description: Generate or regenerate CUE schemas under crd/ with `cue get crd`. Use when a component's custom resources need typing and the schema is not in the CUE Central Registry (cue.dev/x/crd/...) — covers where to get the CRD YAML, layout, the generate procedure, the experiment header and post-generation cleanup.
---

# CRD Generation

First check the CUE Central Registry: `cue.dev/x/crd/<group>` modules exist for many
projects (Flux: `cue.dev/x/crd/fluxcd.io`, cert-manager: `cue.dev/x/crd/cert-manager.io`).
Probe with `curl -s https://registry.cue.works/v2/cue.dev/x/crd/<group>/tags/list` and
prefer a registry module (`cue mod get`, then import it) over generating.

Only when it is missing, generate a schema into `crd/`.

## Layout

```
crd/<short-name>/<version>/<kind>.cue
```

- One directory per CRD group (`fluxcd.controlplane.io` → `crd/fluxoperator/`).
- The version subdirectory matches `spec.versions[].name`; files declare `package <version>`.
- Import as `fluxoperator_v1 "github.com/selfuryon/awesome-cue-infra/crd/fluxoperator/v1"`
  and wire the kind into `#ScopedTypes`/`#GlobalTypes` in `apps/global.cue`.

## Getting the CRD YAML

Prefer the upstream release over a live cluster, pinned to the version in
`apps/registry/latest.json`:

```bash
mkdir -p /tmp/crds
# from the project's repo/release assets, e.g. flux-operator:
curl -sfL https://raw.githubusercontent.com/controlplaneio-fluxcd/flux-operator/v0.61.0/config/crd/bases/fluxcd.controlplane.io_fluxinstances.yaml \
  -o /tmp/crds/fluxinstances.fluxcd.controlplane.io.yaml
# or from a chart:
helm template x oci://<chart> --version <v> --include-crds | yq 'select(.kind == "CustomResourceDefinition")' -s '.metadata.name + ".yaml"'
# or from a cluster:
kubectl get crd <name> -o yaml > /tmp/crds/<name>.yaml
```

## Procedure

```bash
mkdir -p crd/<short-name>
(cd crd/<short-name> && cue get crd --group <group> -s /tmp/crds/*.<group>.yaml)

# prepend the experiment header
for f in crd/<short-name>/v*/*.cue; do
  { echo "@experiment(explicitopen)"; echo; cat "$f"; } > "$f.tmp" && mv "$f.tmp" "$f"
done

# strip generator artifacts (below), then
cue fmt crd/<short-name>/v*/*.cue
bash .github/cue-vet.bash
```

## Experiment header

Generated files use only `@experiment(explicitopen)`, not the three-experiment header
of hand-written CUE.

## Post-generation cleanup

- **`import (...)` block**: drop. Replace validator calls that used it:
  `strings.MaxRunes(N)` / `strings.MinRunes(N) &` → `string`, `time.Time` → `string`.
- **`_embeddedResource` reference and its `_embeddedResource: { ... }` block**: drop.
  The trailing concrete `apiVersion`, `kind` and `metadata!` already pin what we need.
- **Top-level `status?: { ... }`** with its preceding comment: drop (controller-owned).
- **`...` inside the trailing `metadata!: { ... }`**: drop.

Then `cue fmt` and `bash .github/cue-vet.bash`.
