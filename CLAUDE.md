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
  <category>/<component>/      one package per component (gitops, network, security,
                               storage, examples)
  registry/                    latest.json (Renovate) + #Resolve (channel + pins)
crd/<short>/<version>/         CUE schemas generated with `cue get crd`
clusters/
  clusters.cue                 the Clusters registry
  defaults.cue                 reusable cluster definitions (#Core, #Homelab), package defaults
  <cluster>/default.cue        `cluster: defaults.#X & {config, #pins, #releases}` + overrides
  <cluster>/pins.json          component version pins
  <cluster>/releases.json      artifact versions the cluster runs
  <cluster>/release/{flux,argo}/manifests.yaml   generated release layer (committed)
  <cluster>/secrets/<set>/*.sops.yaml            SOPS-encrypted Secrets (Flux sets only)
  <cluster>/talos/             Talos machine config patches + gen.sh
ext_tool.cue                   `cue cmd` commands
scripts/                       render / publish / release / ghcr-cleanup
docs/                          runbooks
```

## Components and versions

- `apps/<category>/<x>`: `#X: {#cluster: apps.#Cluster, #version: string, component: apps.#Component & {...}}`.
  A component is defined once and belongs to a set (`set: *"system" | string`); the set's
  controller decides the wrapper: a chart becomes a Flux source + `HelmRelease` or an
  Argo CD `Application`; plain `manifests` go into the same artifact.
- Sets (`config.sets`, like etherno-infra projects): each set is a project with its own
  artifact `<cluster>-<set>`, releases.json entry, release and rollback. Defaults:
  `system` (Flux: platform) and `apps` (Argo, `dependsOn: ["system"]`). Add sets per
  cluster (`cluster: config: sets: monitoring: controller: "flux"`) and move components
  (`cluster: components: x: set: "monitoring"`). Set `dependsOn` becomes Flux
  Kustomization `dependsOn`; Argo sets wait for the Flux sets they depend on.
- `clusters/defaults.cue` (package `defaults`) holds `#Cluster` (version resolution,
  render, release layer, projects) and component sets: `#Core` (flux-operator, Cilium,
  Argo CD) and `#Homelab` (Core + cert-manager, Kyverno, local-path, whoami). A cluster unifies one
  with its config and inputs, then adds components (`cluster: components: x: ...`, aliased
  import `app_<x>`) or overrides values (`cluster: components: <x>: values: ...`).
  Unification cannot remove a component: pick the smallest definition and add to it.
- In a definition literal (`#Core: #Cluster & {...}`) fields of `#Cluster` are not in
  lexical scope; declare them (`config: _`, `versions: _`) before referencing them.
- Versions: `apps/registry/latest.json` (Renovate, auto-merged) → `clusters/<name>/pins.json`.
  `config.channel: "fast"` uses latest.json with pins on top; `"stable"` uses pins only
  (every component must be pinned).
- Promotion: `cue cmd promote -t to=<cluster> [-t from=<latest|cluster>] [-t components=a,b]`
  (or the _Promote_ workflow) writes versions from latest.json or from what another cluster
  resolves (`cue cmd versions`) into the target's pins.json. Without `components` it touches
  every component the target resolves; an explicit list can also add new pins. Key order
  in pins.json is preserved, so the PR diff shows only the changed lines.
- Each cluster has its own component set; `beta-01` is a manifest-only example
  (`publish: false`: rendered and diffed in PRs, never published) on the stable channel.

## Delivery and releases

- Projects per cluster: `bootstrap` (applied by hand once) and one per set
  (published as `ghcr.io/selfuryon/awesome-cue-infra/<cluster>-<project>`). Only clusters
  with `config.publish` get artifacts and release PRs.
- Artifact tags are content hashes: unchanged content is never re-published.
- Clusters never follow `latest`. The FluxInstance syncs `clusters/<name>/release/flux`
  from Git; per Flux set it pins the artifact by digest (cosign-verified) behind an
  OCIRepository + Kustomization, and applies `release/argo` (one Application per Argo set,
  pinned by digest) once the Flux sets those depend on are ready.
- Publish on `main` → release PR per cluster editing `releases.json` + release layer
  (auto-merged when `config.release.autoMerge`). Rollback = revert the release PR.
- Never hand-edit `clusters/*/release/`; edit `releases.json` and run `cue cmd write-release`.

## Commands

```bash
bash .github/cue-vet.bash                              # vet every package (do not use `cue vet ./...`)
cue cmd dump -t cluster=alpha-01 -t project=system     # render a project (bootstrap or a set)
cue cmd list-projects | list-artifacts | list-clusters | versions
cue cmd promote -t to=beta-01 -t from=alpha-01 -t components=cilium
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
`clusters/<name>/secrets/<set>/`. They ship inside that set's artifact (Flux sets only;
`scripts/render.sh` refuses Argo sets) and are decrypted by Flux (`flux-system/sops-age`). The age identity is `.secrets/sops/age.key`
(`SOPS_AGE_KEY_FILE`); never print or commit it. Argo apps get their Secrets from
Flux as well.

## Safety

- `.secrets/` holds kubeconfig/talosconfig/age key: never read values into output.
- Do not run `kubectl apply`, `talosctl apply-config`, `bootstrap`, `reset` or anything
  that mutates a cluster without the user's explicit go-ahead.
- Workflows: actions pinned by SHA, `persist-credentials: false`, no `${{ }}` inside
  `run:` (pass through `env:`), minimal `permissions`. Run `zizmor .github/workflows`.

## Adding things

- New component: `apps/<category>/<x>`, add it to the cluster's `components`, add its version to
  `apps/registry/latest.json` (and pins.json for stable clusters). See `.claude/skills/add-component`.
- New CRD schema: `.claude/skills/crd-generation`.
- New cluster: `clusters/<name>/{default.cue,pins.json,releases.json}` based on a
  definition from `clusters/defaults.cue`, register in `clusters/clusters.cue`, run `cue cmd write-release`, follow `docs/bootstrap.md`.
