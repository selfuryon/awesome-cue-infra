package argocd

import "github.com/selfuryon/awesome-cue-infra/apps"

// Argo CD for user applications, headless: no API server/UI, no Dex, no
// notifications, no ApplicationSet controller. Use `argocd --core` with the
// kubeconfig. Applications come from the Argo artifact (release layer).
#ArgoCD: {
	#cluster: apps.#Cluster
	#version: string

	component: apps.#Component & {
		name:      "argo-cd"
		namespace: apps.#ArgoNamespace
		chart: {
			kind:    "oci"
			url:     "oci://ghcr.io/argoproj/argo-helm"
			name:    "argo-cd"
			version: #version
		}
		values: {
			fullnameOverride: "argocd"
			crds: {
				install: true
				keep:    true
			}
			server: enabled:        false
			dex: enabled:           false
			notifications: enabled: false
			// The chart has no switch for it; the Deployment is dropped below.
			applicationSet: replicas: 0
		}
		postRenderPatches: [{
			target: {kind: "Deployment", name: "argocd-applicationset-controller"}
			patch: """
				$patch: delete
				apiVersion: apps/v1
				kind: Deployment
				metadata:
				  name: argocd-applicationset-controller
				"""
		}]

		manifests: global: namespace: (apps.#ArgoNamespace): {}
	}
}
