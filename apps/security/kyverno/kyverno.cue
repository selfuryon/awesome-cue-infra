package kyverno

import "github.com/selfuryon/awesome-cue-infra/apps"

#namespace: "kyverno"

// Kyverno policy engine. Controllers run with chart defaults (one replica
// each), which fits a single-node cluster. Policies are separate CRs and go
// into a set that depends on the one carrying Kyverno.
#Kyverno: {
	#cluster: apps.#Cluster
	#version: string

	component: apps.#Component & {
		name:      "kyverno"
		namespace: #namespace
		chart: {
			kind:    "oci"
			url:     "oci://ghcr.io/kyverno/charts"
			name:    "kyverno"
			version: #version
		}
		values: {
			crds: install: true
		}

		manifests: global: namespace: (#namespace): {}
	}
}
