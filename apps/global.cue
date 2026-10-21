package apps

import (
	"strings"
	apps_v1 "cue.dev/x/k8s.io/api/apps/v1"
	core_v1 "cue.dev/x/k8s.io/api/core/v1"
	rbac_v1 "cue.dev/x/k8s.io/api/rbac/v1"
	argo_v1 "cue.dev/x/argo/cd/v1alpha1"
	flux_source_v1 "cue.dev/x/crd/fluxcd.io/source/v1"
	flux_helm_v2 "cue.dev/x/crd/fluxcd.io/helm/v2"
	flux_kustomize_v1 "cue.dev/x/crd/fluxcd.io/kustomize/v1"
	fluxoperator_v1 "github.com/selfuryon/awesome-cue-infra/crd/fluxoperator/v1"
)

// Kubernetes Types: cluster scoped
#GlobalTypes: [string]~(TYPE,_): [string]~(ID,_): {
	apiVersion: *"v1" | string
	kind:       *strings.ToTitle(TYPE) | string

	metadata: name:   *ID | string
	metadata: labels: _defaultLabels
}

#GlobalTypes: {
	namespace: [string]: core_v1.#Namespace & {
		// Pod Security Standards: baseline is enforced unless a namespace
		// explicitly opts into privileged (e.g. hostPath provisioners).
		metadata: labels: {
			"pod-security.kubernetes.io/enforce": *"baseline" | "privileged" | "restricted"
			"pod-security.kubernetes.io/audit":   *"restricted" | "baseline" | "privileged"
			"pod-security.kubernetes.io/warn":    *"restricted" | "baseline" | "privileged"
		}
	}
	clusterRole: [string]:        rbac_v1.#ClusterRole
	clusterRoleBinding: [string]: rbac_v1.#ClusterRoleBinding
}

// Kubernetes Types: namespace scoped
#ScopedTypes: [string]~(TYPE,_): [string]~(ID,_): {
	apiVersion: *"v1" | string
	kind:       *strings.ToTitle(TYPE) | string

	metadata: name:   *ID | string
	metadata: labels: _defaultLabels
}

#ScopedTypes: {
	serviceAccount: [string]: core_v1.#ServiceAccount
	role: [string]:           rbac_v1.#Role
	roleBinding: [string]:    rbac_v1.#RoleBinding
	configMap: [string]:      core_v1.#ConfigMap
	service: [string]:        core_v1.#Service
	deployment: [string]:     apps_v1.#Deployment
	statefulSet: [string]:    apps_v1.#StatefulSet
	daemonSet: [string]:      apps_v1.#DaemonSet

	// Flux
	gitRepository: [string]:  flux_source_v1.#GitRepository
	helmRepository: [string]: flux_source_v1.#HelmRepository
	ociRepository: [string]:  flux_source_v1.#OCIRepository
	helmRelease: [string]:    flux_helm_v2.#HelmRelease
	kustomization: [string]:  flux_kustomize_v1.#Kustomization
	fluxInstance: [string]:   fluxoperator_v1.#FluxInstance

	// Argo CD
	application: [string]: argo_v1.#Application
	appProject: [string]:  argo_v1.#AppProject
}

// A set of manifests: cluster scoped objects plus objects per namespace.
#Manifests: {
	global: #GlobalTypes
	scoped: [string]: #ScopedTypes
	scoped: [string]~(ns,_): [string]~(type,_): [string]~(name,_): {
		metadata: namespace: ns
	}
}

_defaultLabels: {
	"app.kubernetes.io/part-of": "awesome-cue-infra"
}
