package whoami

import "github.com/selfuryon/awesome-cue-infra/apps"

#namespace: "whoami"

// Example user application delivered by Argo CD: a tiny HTTP echo server
// behind a dual-stack LoadBalancer (node IPAM).
#Whoami: {
	#cluster: apps.#Cluster
	#version: string

	let _labels = {"app.kubernetes.io/name": "whoami"}

	component: apps.#Component & {
		name:      "whoami"
		namespace: #namespace
		set:       "apps"

		manifests: global: namespace: (#namespace): metadata: labels: {
			"pod-security.kubernetes.io/enforce": "restricted"
		}
		manifests: scoped: (#namespace): {
			deployment: whoami: spec: {
				replicas: *1 | int
				selector: matchLabels: _labels
				template: {
					metadata: labels: _labels
					spec: {
						securityContext: {
							runAsNonRoot: true
							runAsUser:    65534
							seccompProfile: type: "RuntimeDefault"
						}
						containers: [{
							name:  "whoami"
							image: "docker.io/traefik/whoami:\(#version)"
							args:  ["--port", "8080"]
							ports: [{name: "http", containerPort: 8080}]
							securityContext: {
								allowPrivilegeEscalation: false
								readOnlyRootFilesystem:   true
								capabilities: drop: ["ALL"]
							}
							resources: {
								requests: {cpu: "10m", memory: "16Mi"}
								limits: memory: "32Mi"
							}
						}]
					}
				}
			}
			service: whoami: spec: {
				type:           "LoadBalancer"
				ipFamilyPolicy: "PreferDualStack"
				selector:       _labels
				ports:          [{name: "http", port: 80, targetPort: "http"}]
			}
		}
	}
}
