package kyverno

import "github.com/selfuryon/awesome-cue-infra/apps"

#namespace: "kyverno-system"

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

		// GeneratingPolicies create namespace defaults (apps/security/namespacepolicy):
		// aggregate the permissions into the background (creates them) and
		// admission (validates policies) controllers.
		manifests: global: clusterRole: "kyverno:generate-namespace-defaults": {
			apiVersion: "rbac.authorization.k8s.io/v1"
			metadata: labels: {
				"rbac.kyverno.io/aggregate-to-background-controller": "true"
				"rbac.kyverno.io/aggregate-to-admission-controller":  "true"
			}
			rules: [{
				apiGroups: ["cilium.io"]
				resources: ["ciliumnetworkpolicies"]
				verbs:     ["create", "update", "patch", "delete", "get", "list", "watch"]
			}, {
				apiGroups: [""]
				resources: ["limitranges"]
				verbs:     ["create", "update", "patch", "delete", "get", "list", "watch"]
			}]
		}

		// DeletingPolicies (apps/security/podpolicy) remove finished pods.
		manifests: global: clusterRole: "kyverno:cleanup-pods": {
			apiVersion: "rbac.authorization.k8s.io/v1"
			metadata: labels: "rbac.kyverno.io/aggregate-to-cleanup-controller": "true"
			rules: [{
				apiGroups: [""]
				resources: ["pods"]
				verbs:     ["get", "list", "watch", "delete"]
			}]
		}
	}
}
