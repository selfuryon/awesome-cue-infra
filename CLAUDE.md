# CLAUDE.md

Homelab GitOps repo: Talos Kubernetes clusters whose manifests are written in
CUE, rendered in CI, published to GHCR as OCI artifacts and delivered by Flux
(platform) and Argo CD (user applications).

## Layout

```
apps/
  global.cue, cluster.cue,     shared types: #Manifests, #Cluster, #Component,
  component.cue, render.cue,   #Render (component → Flux/Argo wrapper),
  release.cue                  #Release (release layer)
  <component>/                 one package per component (chart + values + manifests)
  registry/                    latest.json (Renovate) + #Resolve (channel + pins)
crd/<short>/<version>/         CUE schemas generated with `cue get crd`
clusters/
  clusters.cue                 the Clusters registry
  <cluster>/default.cue        config, components, overrides, projects
  <cluster>/pins.json          component version pins
  <cluster>/releases.json      artifact versions the cluster runs
  <cluster>/release/{flux,argo}/manifests.yaml   generated release layer (committed)
  <cluster>/secrets/*.sops.yaml                  SOPS-encrypted Secrets
  <cluster>/talos/             Talos machine config patches + gen.sh
ext_tool.cue                   `cue cmd` commands
scripts/                       render / publish / release / ghcr-cleanup
docs/                          runbooks
```

## Components and versions

- `apps/<x>`: `#X: {#cluster: apps.#Cluster, #version: string, component: apps.#Component & {...}}`.
  A component is defined once; `controller: "flux" | "argo"` only decides the wrapper:
  a chart becomes a Flux source + `HelmRelease` or an Argo CD `Application`; plain
  `manifests` go into the same artifact.
- `clusters/<name>/default.cue` lists the components it runs (aliased imports
  `app_<x>`), passes versions and overrides values (`components: <x>: values: ...`).
- Versions: `apps/registry/latest.json` (Renovate, auto-merged) → `clusters/<name>/pins.json`.
  `config.channel: "fast"` uses latest.json with pins on top; `"stable"` uses pins only
  (every component must be pinned). The _Pin_ workflow copies latest versions into a
  cluster's pins.json via PR.

## Delivery and releases

- Projects per cluster: `bootstrap` (applied by hand once), `flux`, `argo`
  (published as `ghcr.io/selfuryon/awesome-cue-infra/<cluster>-<project>`).
- Artifact tags are content hashes: unchanged content is never re-published.
- Clusters never follow `latest`. The FluxInstance syncs `clusters/<name>/release/flux`
  from Git; that layer pins the Flux artifact by digest (cosign-verified) and applies
  `release/argo` (root Argo Application pinned by digest).
- Publish on `main` → release PR per cluster editing `releases.json` + release layer
  (auto-merged when `config.release.autoMerge`). Rollback = revert the release PR.
- Never hand-edit `clusters/*/release/`; edit `releases.json` and run `cue cmd write-release`.

## Commands

```bash
bash .github/cue-vet.bash                              # vet every package (do not use `cue vet ./...`)
cue cmd dump -t cluster=alpha-01 -t project=flux       # render a project
cue cmd list-projects | list-artifacts | list-clusters
cue cmd write-release                                  # regenerate release layers
scripts/render.sh alpha-01 flux /tmp/out               # artifact contents incl. secrets
nix fmt                                                # treefmt (nixfmt, prettier, cue fmt)
```

## CUE rules

- Every hand-written `.cue` file starts with:
  ```cue
  @experiment(aliasv2)
  @experiment(explicitopen)
  @experiment(try)
  ```
  (`@extern(embed)` first when the file embeds JSON). Generated `crd/` files use only
  `@experiment(explicitopen)`.
- The CUE version is not pinned: it comes from nixpkgs via `flake.lock` (same locally and
  in CI), and the weekly flake PR is the upgrade path.
- Scope trap: inside `X & {#cluster: #cluster}` the right-hand `#cluster` refers to the
  inner field itself. Bind outer values with `let` first (`let _c = #cluster`).
- Field names shadow imports of the same name: alias component imports (`app_cilium`).
- Kinds whose title-cased key is wrong (`ociRepository` → `OCIRepository`) are fixed by the
  CRD schema's concrete `kind`; plain types must set `kind` explicitly if the default is wrong.
- Verify refactors by comparing `cue cmd dump` output before and after.

## Secrets

SOPS + age. `.sops.yaml` encrypts `data`/`stringData` of files under
`clusters/<name>/secrets/`. They ship inside the Flux artifact and are decrypted by
Flux (`flux-system/sops-age`). The age identity is `.secrets/sops/age.key`
(`SOPS_AGE_KEY_FILE`); never print or commit it. Argo apps get their Secrets from
Flux as well.

## Safety

- `.secrets/` holds kubeconfig/talosconfig/age key: never read values into output.
- Do not run `kubectl apply`, `talosctl apply-config`, `bootstrap`, `reset` or anything
  that mutates a cluster without the user's explicit go-ahead.
- Workflows: actions pinned by SHA, `persist-credentials: false`, no `${{ }}` inside
  `run:` (pass through `env:`), minimal `permissions`. Run `zizmor .github/workflows`.

## Adding things

- New component: `apps/<x>`, add it to the cluster's `components`, add its version to
  `apps/registry/latest.json` (and pins.json for stable clusters). See `.claude/skills/add-component`.
- New CRD schema: `.claude/skills/crd-generation`.
- New cluster: `clusters/<name>/{default.cue,releases.json}`, register in
  `clusters/clusters.cue`, run `cue cmd write-release`, follow `docs/bootstrap.md`.
