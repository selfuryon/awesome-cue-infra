package podpolicy

import (
	"encoding/json"

	"github.com/selfuryon/awesome-cue-infra/apps"
)

// Workload hygiene, as Kyverno CEL policies (policies.kyverno.io/v1):
//
//   disallow-latest-tag        Deny   images carry an explicit tag or digest, never :latest
//   restrict-image-registries  Deny   images come from security.allowedRegistries
//   disallow-default-namespace Deny   no workloads in `default`
//   restrict-service-exposure  Deny   LoadBalancer/NodePort only in namespaces labelled
//                                     awesome-cue-infra/expose=true (or *-system)
//   require-requests-limits    Audit  containers in application namespaces set cpu/memory
//                                     requests and a memory limit (LimitRange defaults there)
//   cleanup-finished-pods      hourly delete Succeeded/Failed pods not owned by a Job
//
// Pods are checked at admission and in the background (policy reports:
// `kubectl get policyreports -A`). Lives in the `policy` set.

// Namespace label that allows LoadBalancer/NodePort Services.
#ExposeLabel: "awesome-cue-infra/expose"

// Pods (CREATE/UPDATE), with every container of the pod in variables.containers.
_pods: {
	evaluation: background: enabled: true
	matchConstraints: resourceRules: [{
		apiGroups:   [""]
		apiVersions: ["v1"]
		operations:  ["CREATE", "UPDATE"]
		resources:   ["pods"]
	}]
	variables: [{
		name:       "containers"
		expression: "object.spec.containers + object.spec.?initContainers.orValue([]) + object.spec.?ephemeralContainers.orValue([])"
	}, ...]
}

#PodPolicy: {
	#cluster: apps.#Cluster

	let _registries = json.Marshal(#cluster.security.allowedRegistries)

	component: apps.#Component & {
		name:      "pod-policy"
		namespace: "kyverno-system"
		set:       "policy"

		manifests: global: validatingPolicy: {
			"disallow-latest-tag": spec: _pods & {
				validationActions: ["Deny"]
				validations: [{
					expression: "variables.containers.all(c, c.image.matches('^.+(:[^:/@]+(@sha256:[0-9a-f]{64})?|@sha256:[0-9a-f]{64})$') && !c.image.matches(':latest(@|$)'))"
					message:    "Images must be pinned to a tag other than latest, or to a digest."
				}]
			}

			"restrict-image-registries": spec: _pods & {
				validationActions: ["Deny"]
				variables:         [_, {name: "registries", expression: _registries}]
				validations: [{
					expression:        "variables.containers.all(c, variables.registries.exists(r, c.image.startsWith(r)))"
					messageExpression: "'Images must come from one of ' + variables.registries.join(', ') + ' and name the registry explicitly.'"
					message:           "Images must come from an allowed registry."
				}]
			}

			"disallow-default-namespace": spec: {
				validationActions: ["Deny"]
				evaluation: background: enabled: true
				matchConstraints: resourceRules: [{
					apiGroups:   ["", "apps", "batch"]
					apiVersions: ["v1"]
					// CREATE only: the apiserver keeps updating its own objects there.
					operations: ["CREATE"]
					resources:  ["pods", "deployments", "statefulsets", "daemonsets", "jobs", "cronjobs"]
				}]
				validations: [{
					expression: "object.metadata.?namespace.orValue('') != 'default'"
					message:    "Workloads must not run in the default namespace."
				}]
			}

			"restrict-service-exposure": spec: {
				validationActions: ["Deny"]
				evaluation: background: enabled: true
				matchConstraints: resourceRules: [{
					apiGroups:   [""]
					apiVersions: ["v1"]
					operations:  ["CREATE", "UPDATE"]
					resources:   ["services"]
				}]
				validations: [{
					expression: """
						!(object.spec.?type.orValue('ClusterIP') in ['LoadBalancer', 'NodePort'])
						|| object.metadata.?namespace.orValue('').endsWith('-system')
						|| namespaceObject.?metadata.?labels.orValue({}).exists(k, k == '\(#ExposeLabel)' && namespaceObject.metadata.labels[k] == 'true')
						"""
					message: "LoadBalancer/NodePort Services expose the node's addresses: label the namespace \(#ExposeLabel)=true to allow them."
				}]
			}

			"require-requests-limits": spec: _pods & {
				validationActions: ["Audit"]
				// Applications only: platform charts come with their own defaults. Pods
				// only: autogen rules for controllers read the pod template's metadata,
				// which has no namespace, and would miss the condition below.
				autogen: podControllers: controllers: []
				matchConditions: [{name: "application-namespace", expression: "!object.metadata.?namespace.orValue('').endsWith('-system')"}]
				validations: [{
					expression: """
						variables.containers.all(c,
						  c.?resources.?requests.?cpu.hasValue() &&
						  c.?resources.?requests.?memory.hasValue() &&
						  c.?resources.?limits.?memory.hasValue())
						"""
					message: "Containers should set cpu and memory requests and a memory limit."
				}]
			}
		}

		manifests: global: deletingPolicy: "cleanup-finished-pods": spec: {
			schedule: "0 * * * *"
			matchConstraints: resourceRules: [{
				apiGroups:   [""]
				apiVersions: ["v1"]
				operations:  ["*"]
				resources:   ["pods"]
				scope:       "Namespaced"
			}]
			conditions: [{
				name:       "finished"
				expression: "object.status.?phase.orValue('') in ['Succeeded', 'Failed']"
			}, {
				// Jobs clean up after themselves (ttlSecondsAfterFinished).
				name:       "not-from-a-job"
				expression: "!object.metadata.?ownerReferences.orValue([]).exists(o, o.kind == 'Job')"
			}]
		}
	}
}
