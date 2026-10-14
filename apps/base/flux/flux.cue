@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package flux

import (
	"strings"
	"github.com/selfuryon/awesome-cue-infra/apps"
)

#namespace: "flux-system"

// flux-operator plus the FluxInstance that installs Flux itself and syncs
// the cluster's release layer from Git. The same manifests are applied by
// hand once at bootstrap (`cue cmd dump -t project=bootstrap`); afterwards
// Flux manages both, including upgrades of the operator chart.
#Flux: {
	#cluster: apps.#Cluster
	#versions: {
		operator!: string
		flux!:     string
	}

	component: apps.#Component & {
		name:      "flux-operator"
		namespace: #namespace
		chart: {
			kind:    "oci"
			url:     "oci://ghcr.io/controlplaneio-fluxcd/charts"
			name:    "flux-operator"
			version: #versions.operator
		}
		values: {
			// No UI: Flux is driven through Git and the CLI only.
			web: enabled: false
		}

		manifests: global: namespace: (#namespace): {}
		manifests: scoped: (#namespace): fluxInstance: flux: spec: {
			distribution: {
				version:  strings.TrimPrefix(#versions.flux, "v")
				registry: "ghcr.io/fluxcd"
				artifact: "oci://ghcr.io/controlplaneio-fluxcd/flux-operator-manifests"
			}
			components: [
				"source-controller",
				"kustomize-controller",
				"helm-controller",
				"notification-controller",
			]
			cluster: {
				type:          "kubernetes"
				size:          "small"
				multitenant:   false
				networkPolicy: true
				domain:        "cluster.local"
			}
			sync: {
				kind:     "GitRepository"
				url:      apps.#Repo.url
				ref:      "refs/heads/\(apps.#Repo.branch)"
				path:     "clusters/\(#cluster.name)/release/flux"
				interval: "5m"
			}
		}
	}
}
