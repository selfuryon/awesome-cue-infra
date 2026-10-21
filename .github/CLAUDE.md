# CI / Workflow Context

Loaded when working under `.github/`. See the repo root `CLAUDE.md` for
everything else.

## Workflows

| workflow             | trigger         | does                                                                                                                                     |
| -------------------- | --------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `integration.yaml`   | PR, merge queue | nix checks, cue vet, release-layer sync, Talos validation, per-project manifest diff (narrowed to affected clusters), `final-check` gate |
| `publish.yaml`       | push to `main`  | content-addressed artifacts to GHCR, cosign signature + SLSA provenance, one release PR per publishing cluster                           |
| `flake-updates.yaml` | weekly          | `nix flake update` PR, auto-merged                                                                                                       |
| `promote.yaml`       | manual          | `cue cmd promote` into a cluster's pins.json, PR                                                                                         |
| `cue-compat.yaml`    | manual          | vet + render every project on another CUE release (`latest`, tag, `master`) before moving the pin                                        |
| `cleanup.yaml`       | weekly          | prune GHCR versions not pinned by any releases.json (keeps the last 10)                                                                  |
| `labeler.yaml`       | PR              | path labels                                                                                                                              |

`final-check` is the only required status. It accepts a skipped `manifests-diff`
only when `prepare` found nothing to render.

## Tools in CI

Jobs run tools through the devshell (`nix develop .#ci -c ...`): the same CUE
(pinned in `nix/overlay.nix`), oras, cosign, jq, yq, gh, talosctl and Python with
PyYAML as locally. The PR diff renders the base branch with the base's own
devshell. `cue-compat.yaml` is the exception: it installs the CUE under test.
`GOGC=200` is set for CUE-heavy workflows.

## Workflow Security Rules

### Template Injection Prevention

Never use `${{ }}` directly in `run:` blocks. Always use environment variables:

```yaml
# WRONG - vulnerable to injection
- run: echo "${{ inputs.name }}"

# CORRECT - safe via env
- run: echo "${INPUT_NAME}"
  env:
    INPUT_NAME: ${{ inputs.name }}
```

Same for step outputs (`STEPS_FOO_OUTPUTS_BAR: ${{ steps.foo.outputs.bar }}`).

### Other Rules

- Pin actions by SHA: `uses: actions/checkout@SHA # vX.Y.Z` (Renovate keeps them current).
- Local actions, if ever added, use the self-repository form `uses: $/.github/actions/<name>`
  (zizmor ≥ 1.30 `self-repository` audit), never `./...`.
- `persist-credentials: false` on every checkout; minimal `permissions` per job.
- Anything that writes to PRs or pushes branches uses the GitHub App token
  (`APP_CLIENT_ID` / `APP_PRIVATE_KEY`): PRs opened with `GITHUB_TOKEN` do not trigger CI.
- Run `zizmor .github/workflows` (also a pre-commit hook).

## Cosign

Signatures and attestations use the legacy format
(`--new-bundle-format=false --use-signing-config=false`): it is what Flux's
OCIRepository verification reads, and it stores them as `sha256-<digest>.sig` /
`.att` tags, which `scripts/ghcr-cleanup.sh` keeps together with their artifact.
