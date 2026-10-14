# Contributing

## Setup

```bash
direnv allow   # or: nix develop
```

The devshell provides cue, flux, argocd, kubectl, helm, talosctl, oras, cosign,
sops/age and the pre-commit hooks. Tool configs point into the gitignored `.secrets/`.

## Before pushing

```bash
bash .github/cue-vet.bash          # all CUE packages
cue cmd write-release              # if releases.json or the release model changed
nix fmt                            # treefmt: nixfmt, prettier, cue fmt
pre-commit run --all-files         # + statix, deadnix, zizmor
pinact run --update                # when touching workflows
```

## Conventions

- Conventional Commits for commits and PR titles (`feat(cilium): ...`,
  `chore(deps): ...`); branches `<type>/<short-description>`.
- One concern per PR; the manifest diff comment is the review surface.
- Workflows: actions pinned by commit SHA with a version comment,
  `persist-credentials: false`, explicit minimal `permissions`, never `${{ }}` inside
  `run:` (use `env:`).
- Secrets only as SOPS files under `clusters/<cluster>/secrets/`.
