---
name: add-component
description: Add a platform component (Flux) or a user application (Argo CD) to the repo — component package, version registry, cluster wiring and overrides, verification. Use whenever a new Helm chart or set of manifests should be deployed to a cluster.
---

# Adding a component

A component is defined once in `apps/<category>/<x>`; `controller` picks the wrapper:

| controller         | chart becomes                                                    | lands in artifact |
| ------------------ | ---------------------------------------------------------------- | ----------------- |
| `"flux"` (default) | `HelmRepository`/`OCIRepository`/`GitRepository` + `HelmRelease` | `<cluster>-flux`  |
| `"argo"`           | Argo CD `Application` (helm source, `valuesObject`)              | `<cluster>-argo`  |

Platform pieces (CNI, cert-manager, storage, operators) → Flux. User apps → Argo.

## 1. Component package

`apps/<category>/<x>/<x>.cue` (categories: gitops, network, security, storage, examples; package name without dashes):

```cue
@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package x

import "github.com/selfuryon/awesome-cue-infra/apps"

#namespace: "x"

#X: {
	#cluster: apps.#Cluster
	#version: string

	component: apps.#Component & {
		name:      "x"
		namespace: #namespace
		// controller: "argo"
		chart: {
			kind:    "oci"                    // "helm" | "oci" | "git"
			url:     "oci://ghcr.io/org/charts" // oci: without the chart name
			name:    "x"
			version: #version
			// path: "deploy/chart/x"         // git only
		}
		values: {...}
		// dependsOn: ["cert-manager"]        // Flux only
		// postRenderPatches: [{target: {...}, patch: "..."}] // Flux only

		manifests: global: namespace: (#namespace): {}
		// manifests: scoped: (#namespace): configMap: foo: data: {...}
	}
}
```

- Derive cluster-specific values from `#cluster` (network, storage), not literals.
- Namespaces default to PSA `baseline` enforce; set `"pod-security.kubernetes.io/enforce"`
  explicitly for `privileged`/`restricted`.
- A new resource kind needs a type in `apps/global.cue` (CRD schema from the registry or
  `crd/`, see the crd-generation skill).

## 2. Version

Add to `apps/registry/latest.json` (Renovate keeps it current):

```json
{
  "name": "x",
  "datasource": "docker",
  "package": "ghcr.io/org/charts/x",
  "version": "1.2.3"
}
```

Datasources: `helm` (+ `"registry": "<repo url>"` before `version`), `docker` (OCI charts,
images), `github-tags`, `github-releases`. Keep field order `name, datasource, package,
[registry], version` — the Renovate regex depends on it. For clusters on the `stable`
channel also add it to their `pins.json` (or run the _Promote_ workflow).

## 3. Cluster

Add it to `components` in `clusters/<cluster>/default.cue` with an aliased import
(a field named like the import would shadow it):

```cue
app_x "github.com/selfuryon/awesome-cue-infra/apps/<category>/x"
...
x: (app_x.#X & {#cluster: config, #version: _v.x}).component
```

Overrides go next to it: `components: x: values: foo: "bar"`.
Version pin: `"x": "1.2.2"` in `clusters/<cluster>/pins.json`.

## 4. Secrets (optional)

`sops clusters/<cluster>/secrets/x.sops.yaml` (a Secret manifest). Shipped in the Flux
artifact; for Argo apps the namespace must exist before Flux applies the Secret
(declare the namespace in a Flux component or accept a retry).

## 5. Verify

```bash
bash .github/cue-vet.bash
cue cmd dump -t cluster=alpha-01 -t project=flux   # or argo
helm template x <chart> --version <v> -f <(cue export ... ) # when unsure about values
```

The PR shows a per-project manifest diff; after merge a release PR switches the cluster.
