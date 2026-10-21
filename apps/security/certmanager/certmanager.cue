package certmanager

import "github.com/selfuryon/awesome-cue-infra/apps"

#namespace: "cert-manager"

#CertManager: {
	#cluster: apps.#Cluster
	#version: string

	component: apps.#Component & {
		name:      "cert-manager"
		namespace: #namespace
		chart: {
			kind:    "oci"
			url:     "oci://quay.io/jetstack/charts"
			name:    "cert-manager"
			version: #version
		}
		values: crds: enabled: true

		manifests: global: namespace: (#namespace): {}
	}
}
