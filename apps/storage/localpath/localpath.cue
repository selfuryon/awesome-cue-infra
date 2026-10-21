package localpath

import "github.com/selfuryon/awesome-cue-infra/apps"

#namespace: "local-path-system"

// Rancher local-path-provisioner on top of the Talos user volume. The chart
// is not published to a Helm repository, so it is taken from the Git tag.
#LocalPath: {
	#cluster: apps.#Cluster
	#version: string

	component: apps.#Component & {
		name:      "local-path-provisioner"
		namespace: #namespace
		chart: {
			kind:    "git"
			url:     "https://github.com/rancher/local-path-provisioner"
			name:    "local-path-provisioner"
			path:    "deploy/chart/local-path-provisioner"
			version: #version
		}
		values: {
			storageClass: {
				create:            true
				name:              "local-path"
				defaultClass:      true
				reclaimPolicy:     "Delete"
				volumeBindingMode: "WaitForFirstConsumer"
			}
			nodePathMap: [{
				node:  "DEFAULT_PATH_FOR_NON_LISTED_NODES"
				paths: [#cluster.storage.localPath]
			}]
		}

		// Helper pods mount host paths.
		manifests: global: namespace: (#namespace): metadata: labels: {
			"pod-security.kubernetes.io/enforce": "privileged"
		}
	}
}
