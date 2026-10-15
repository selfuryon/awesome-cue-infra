[![Nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Nix/NixOS&color=5277C3&style=for-the-badge)](https://nixos.org/)
[![CUE](https://img.shields.io/static/v1?logo=cue&logoColor=white&label=&message=CUE&color=0066FF&style=for-the-badge)](https://cuelang.org/)
[![Flux](https://img.shields.io/static/v1?logo=flux&logoColor=white&label=&message=Flux&color=5468FF&style=for-the-badge)](https://fluxcd.io/)
[![ArgoCD](https://img.shields.io/static/v1?logo=argo&logoColor=white&label=&message=ArgoCD&color=EF7B4D&style=for-the-badge)](https://argoproj.github.io/cd/)
[![Talos](https://img.shields.io/static/v1?logo=talos&logoColor=white&label=&message=Talos&color=FF7300&style=for-the-badge)](https://www.talos.dev/)

# awesome-cue-infra

Homelab infrastructure as CUE: Talos Kubernetes clusters whose manifests are
rendered in CI, published to GHCR as signed OCI artifacts, and delivered by
**Flux** (platform) and **Argo CD** (user applications).

## Structure

```
apps/<category>/<component>/   a component defined once: chart, values, manifests
apps/registry/latest.json      upstream versions (Renovate, auto-merged)
crd/                           generated CUE schemas
clusters/<cluster>/            default.cue (components + overrides), pins.json,
                               releases.json, release/, secrets/, talos/
scripts/                       render, publish, release, ghcr-cleanup
docs/bootstrap.md              GitHub setup and cluster bootstrap
```

Components are grouped into sets (projects): `system` (platform, Flux) and `apps`
(user applications, Argo CD) by default, more per cluster. Each set is its own
artifact and release. The set's controller only changes a component's wrapper: a Flux
source + `HelmRelease`, or an Argo CD `Application`. Each cluster lists the
components it runs and takes versions from `latest.json` (channel `fast`) or only
from its `pins.json` (channel `stable`), pins always winning. The _Promote_
workflow moves versions from `latest` or from one cluster to another.

## Delivery

```
CUE ──(CI on main)──▶ ghcr.io/selfuryon/awesome-cue-infra/<cluster>-<set>:<content-hash>
                                   │ cosign-signed, pinned by digest
release PR edits clusters/<cluster>/releases.json + release/  ──▶ merge = deploy
FluxInstance ─▶ release/flux ─▶ <cluster>-system artifact (platform, incl. Argo CD)
                             └▶ release/argo ─▶ Application per Argo set ─▶ <cluster>-apps artifact
```

No cluster follows `latest`: switching versions is a reviewed (or auto-merged) PR, and
rolling back is reverting it.

## Clusters

| Cluster    | Hardware                         | Notes                                                                       |
| ---------- | -------------------------------- | --------------------------------------------------------------------------- |
| `alpha-01` | Beelink U59 (N5095), Talos v1.14 | single node, dual-stack (IPv6 primary), Cilium native routing + netkit      |
| `beta-01`  | none (manifests only)            | example: different component set, IPv4-only, stable channel with older pins |

## Getting started

```bash
direnv allow
bash .github/cue-vet.bash
cue cmd dump -t cluster=alpha-01 -t project=system
```

See [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/bootstrap.md](docs/bootstrap.md).
