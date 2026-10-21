[![Nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Nix/NixOS&color=5277C3&style=for-the-badge)](https://nixos.org/)
[![CUE](https://img.shields.io/static/v1?logo=cue&logoColor=white&label=&message=CUE&color=0066FF&style=for-the-badge)](https://cuelang.org/)
[![Flux](https://img.shields.io/static/v1?logo=flux&logoColor=white&label=&message=Flux&color=5468FF&style=for-the-badge)](https://fluxcd.io/)
[![ArgoCD](https://img.shields.io/static/v1?logo=argo&logoColor=white&label=&message=ArgoCD&color=EF7B4D&style=for-the-badge)](https://argoproj.github.io/cd/)
[![Talos](https://img.shields.io/static/v1?logo=talos&logoColor=white&label=&message=Talos&color=FF7300&style=for-the-badge)](https://www.talos.dev/)

# awesome-cue-infra

A reusable GitOps template for Talos Kubernetes clusters. Everything a cluster runs
is written in CUE, rendered in CI, published to GHCR as signed OCI artifacts, and
delivered by **Flux** (platform) and **Argo CD** (user applications).

Three things are first-class: every cluster runs **its own set of components**, at
**its own versions**, and versions are **promoted between clusters** explicitly.

## How it works

```
                    apps/registry/latest.json      ◀── Renovate (what upstream offers)
                               │
                               ▼  resolve per cluster
 clusters/<cluster>/pins.json ─┤  channel fast:   latest.json, pins on top
     (component lock)          │  channel stable: pins only
                               ▼
        CUE render ──(CI on main)──▶ ghcr.io/…/<cluster>-<set>:<content-hash>   cosign-signed
                                                     │
 clusters/<cluster>/releases.json ◀── release PR ────┘
     (artifact lock, by digest)
                               │
                               ▼
 FluxInstance ─▶ clusters/<cluster>/release/flux ─▶ <cluster>-system   (Cilium, cert-manager,
                                                 │                       Kyverno, local-path, Argo CD)
                                                 └▶ release/argo ─▶ Argo Application ─▶ <cluster>-apps
```

## Versions are locked, like `Cargo.lock`

Versions are managed the way a package manager does it: an index of what exists, a
lock file with what is actually used, and explicit commands to move the lock.

| Cargo                  | here                                                | what it is                                                               |
| ---------------------- | --------------------------------------------------- | ------------------------------------------------------------------------ |
| crates.io index        | `apps/registry/latest.json`                         | the newest upstream version of every component, kept current by Renovate |
| `Cargo.lock`           | `clusters/<cluster>/pins.json`                      | the exact version of each component **this cluster** runs                |
| `cargo update -p foo`  | `cue cmd promote -t to=<cluster> -t components=foo` | move one pin, nothing else                                               |
| `cargo update`         | `cue cmd promote -t to=<cluster>`                   | move every pin the cluster uses                                          |
| `--locked`             | `channel: "stable"`                                 | nothing moves unless the lock moves                                      |
| a build's image digest | `clusters/<cluster>/releases.json`                  | which rendered artifact (by digest) the cluster deploys                  |

### The unit is a cluster, the granularity is a component

Each cluster has one `pins.json`, keyed by component. A component owns its namespace
(`cert-manager`, `kyverno`, `argocd`, `whoami`, …), so pins can be moved one component,
i.e. one namespace, at a time:

```jsonc
// clusters/beta-01/pins.json — the lock for beta-01
{
  "flux-operator": "0.60.0",
  "flux": "v2.9.5",
  "cilium": "1.20.1",
  "argo-cd": "10.10.2",
  "whoami": "v1.12.0",
}
```

Two channels decide how much the lock holds:

- **`fast`** — the cluster follows `latest.json`; `pins.json` holds only the exceptions
  (`{"cilium": "1.20.1"}` keeps Cilium back while everything else moves). Renovate PRs
  roll out to fast clusters directly. `alpha-01` is fast with an empty lock.
- **`stable`** — `pins.json` is the full lock: every component the cluster uses must be
  pinned, and nothing changes until the lock does. `beta-01` is stable.

### Moving the lock

```bash
# one component from upstream
cue cmd promote -t to=beta-01 -t components=cilium
# cilium: 1.20.1 -> 1.20.3

# what a canary cluster runs, onto another cluster
cue cmd promote -t to=beta-01 -t from=alpha-01

# a component the cluster does not pin yet (e.g. just added on a stable cluster)
cue cmd promote -t to=beta-01 -t components=cert-manager
# cert-manager: (unpinned) -> v1.21.2

cue cmd versions -t cluster=beta-01    # what the cluster resolves now
```

`promote` keeps the key order of `pins.json`, so a PR shows exactly the lines that
moved. The **Promote** workflow runs the same command and opens the PR. Every PR
shows the rendered manifest diff per affected cluster before anything merges.

### Two locks, two steps

`pins.json` locks **inputs** (component versions); `releases.json` locks **outputs**
(the digest of the rendered artifact). Changing a pin changes the render, which CI
publishes as a new content-addressed artifact; a release PR then moves
`releases.json` to its digest. Only that merge deploys, and reverting it rolls back
to the previous digest without rebuilding anything.

## Component sets

Within a cluster, components are grouped into **sets** (projects). Each set is its own
artifact `<cluster>-<set>`, its own entry in `releases.json`, and is released and
rolled back on its own.

| set      | controller                              | holds                                                                           |
| -------- | --------------------------------------- | ------------------------------------------------------------------------------- |
| `system` | Flux (`HelmRelease`)                    | the platform: flux-operator, Cilium, cert-manager, Kyverno, local-path, Argo CD |
| `apps`   | Argo CD (`Application`), after `system` | user applications                                                               |

A component is defined once; its set's controller only decides the wrapper (a Flux
source + `HelmRelease`, or an Argo CD `Application`). Clusters can add sets (e.g.
`monitoring`) and move components between them.

## Clusters

Shared definitions in `clusters/defaults.cue` (`#Core`, `#Homelab`) carry the wiring;
a cluster picks one and adds or overrides on top.

| cluster    | built on         | channel | hardware                         | notes                                                                                           |
| ---------- | ---------------- | ------- | -------------------------------- | ----------------------------------------------------------------------------------------------- |
| `alpha-01` | `#Homelab`       | fast    | Beelink U59 (N5095), Talos v1.14 | single node, dual-stack (IPv6 primary), Cilium native routing + netkit, nodeIPAM LoadBalancers  |
| `beta-01`  | `#Core` + whoami | stable  | none (manifests only)            | different component set, IPv4-only, older pinned versions; rendered and diffed, never published |

## Layout

```
apps/<category>/<component>/   a component: chart, values, manifests
apps/registry/latest.json      upstream versions (Renovate)
crd/                           generated CUE schemas
clusters/defaults.cue          shared cluster definitions
clusters/<cluster>/            default.cue, pins.json, releases.json, release/,
                               secrets/<set>/*.sops.yaml, talos/
scripts/                       render, publish, release, ghcr-cleanup
docs/bootstrap.md              GitHub setup and cluster bootstrap
```

## Day to day

| want to                          | do                                                               |
| -------------------------------- | ---------------------------------------------------------------- |
| change a component or its values | edit CUE → PR (manifest diff) → merge → release PR → merge       |
| take an upstream update          | Renovate PR (auto-merged for minor/patch) → fast clusters follow |
| update a stable cluster          | `cue cmd promote` / _Promote_ workflow → PR                      |
| hold one component back          | add it to the cluster's `pins.json`                              |
| roll back                        | revert the release PR                                            |
| add a secret                     | `sops clusters/<cluster>/secrets/<set>/<name>.sops.yaml`         |

## Getting started

```bash
direnv allow                                       # devshell: cue, flux, argocd, kubectl, sops, …
bash .github/cue-vet.bash                          # validate
cue cmd dump -t cluster=alpha-01 -t project=system # render a set
cue cmd versions                                   # resolved versions per cluster
```

See [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/bootstrap.md](docs/bootstrap.md).
