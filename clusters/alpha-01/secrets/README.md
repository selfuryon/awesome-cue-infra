# alpha-01 secrets

SOPS-encrypted Kubernetes Secrets (`*.sops.yaml`). `scripts/render.sh` copies
them verbatim into the `alpha-01-flux` artifact; Flux decrypts them with the
age identity from the `flux-system/sops-age` Secret.

```sh
# create or edit (opens $EDITOR, encrypts on save)
sops clusters/alpha-01/secrets/<name>.sops.yaml
```

Secrets for Argo CD applications live here too: Flux places them into the
application's namespace (Argo CD cannot decrypt SOPS).
