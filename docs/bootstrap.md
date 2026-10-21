# Bootstrap

How a cluster gets from "Talos + Kubernetes running" to "fully managed by Flux and
Argo CD", plus the one-time GitHub setup. Talos installation itself is in
`clusters/<cluster>/talos/gen.sh`.

## 1. GitHub (once per repository)

1. **GitHub App** (Settings → Developer settings → GitHub Apps → New):
   - Repository permissions: _Contents: read & write_, _Pull requests: read & write_.
   - No webhook. Install it on this repository.
   - Repository variable `APP_CLIENT_ID` = the App's Client ID; repository secret
     `APP_PRIVATE_KEY` = a generated private key (PEM).
   - Used for PR diff comments, release PRs and flake-update PRs. PRs opened with
     `GITHUB_TOKEN` would not trigger CI, so auto-merge would never fire.
2. **Renovate**: install the Renovate GitHub App on the repository
   (config: `.github/renovate.json`).
3. **Settings → General**: enable _Allow auto-merge_ and _Automatically delete head
   branches_; allow squash merging.
4. **Ruleset for `main`**: require status check `final-check`, require a PR, no
   required approvals (bots must be able to auto-merge). Block force pushes.
5. **Labels** used by workflows: `release`, `nix`, `promote`, `renovate`, `security`
   (the labeler creates its own).

## 2. First publish

Merge to `main`. The Publish workflow pushes one artifact per set,
`ghcr.io/selfuryon/awesome-cue-infra/<cluster>-<set>` (`-system`, `-apps`), and opens `release(<cluster>)` PRs.

GHCR creates new packages as **private**. For each package (GitHub profile → Packages):

- _Package settings → Change visibility → Public_ (Flux and Argo pull anonymously).
- _Manage Actions access_: grant this repository the **Admin** role (needed by the
  Registry Cleanup workflow to delete versions).

Then merge (or let auto-merge merge) the release PR. `clusters/<cluster>/releases.json`
now pins both artifacts by digest.

## 3. Cluster

Prerequisites: kubeconfig for the cluster (`.secrets/kubernetes/config`), the age key
`.secrets/sops/age.key`, a merged release PR.

```bash
# age identity for SOPS decryption
kubectl create namespace flux-system
kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey=.secrets/sops/age.key

# flux-operator (same chart/version/values Flux will adopt afterwards)
helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --version "$(jq -r '.components[] | select(.name == "flux-operator").version' apps/registry/latest.json)" \
  --namespace flux-system --set web.enabled=false

# flux-system namespace labels + FluxInstance (syncs clusters/<cluster>/release/flux)
cue cmd dump -t cluster=alpha-01 -t project=bootstrap | kubectl apply --server-side -f -
```

From here on:

1. The FluxInstance installs Flux and syncs `release/flux` from Git.
2. `alpha-01-system` (OCIRepository, cosign-verified) applies the platform: flux-operator
   (adopts the Helm release above), Cilium, cert-manager, Kyverno, local-path-provisioner, Argo CD.
3. `alpha-01-release-argo` (after `alpha-01-system` is ready) applies the Argo
   `Application` `alpha-01-apps`, which syncs the `alpha-01-apps` artifact.

Cilium installed by hand with `helm install cilium` is adopted by the `cilium`
HelmRelease (same release name and namespace, same values) and upgraded in place.

## 4. Verify

```bash
flux get all -A
kubectl -n flux-system get fluxinstance,ocirepository,kustomization
kubectl get helmrelease -A
argocd app list            # ARGOCD_OPTS=--core from the devshell
kubectl -n flux-system get configmap alpha-01-release -o yaml   # deployed versions
```

## Day 2

- Change CUE → PR (manifest diff in comments) → merge → release PR → merge = deploy.
- Rollback: revert the release PR.
- Promote versions (latest → cluster, cluster → cluster): run the _Promote_ workflow.
- Old artifact versions are pruned weekly (_Registry Cleanup_, keeps pinned + last 10).
