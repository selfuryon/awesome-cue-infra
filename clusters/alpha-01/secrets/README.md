# alpha-01 secrets

SOPS-encrypted Kubernetes Secrets, one directory per Flux set
(`<set>/*.sops.yaml`). `scripts/render.sh` copies them verbatim into the
`alpha-01-<set>` artifact; Flux decrypts them with the age identity from the
`flux-system/sops-age` Secret.

```sh
# create or edit (opens $EDITOR, encrypts on save)
sops clusters/alpha-01/secrets/system/<name>.sops.yaml
```

Secrets for Argo CD applications go into a Flux set too (Argo CD cannot
decrypt SOPS); Flux places them into the application's namespace.
