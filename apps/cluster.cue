@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package apps

// Repository coordinates: artifacts are published to GHCR under this path and
// Flux syncs the release layer from this Git repository.
#Repo: {
	url:      "https://github.com/selfuryon/awesome-cue-infra.git"
	branch:   "main"
	registry: "ghcr.io/selfuryon/awesome-cue-infra"
	// Identity of the workflow that signs artifacts (cosign keyless).
	signer: {
		issuer:  "^https://token\\.actions\\.githubusercontent\\.com$"
		subject: "^https://github\\.com/selfuryon/awesome-cue-infra/\\.github/workflows/publish\\.yaml@refs/heads/main$"
	}
}

// Cluster-wide facts that components derive their configuration from.
#Cluster: {
	name!: string

	// Delivery controllers: the Flux artifact carries the platform, the Argo
	// artifact carries user applications.
	controllers: ["flux", "argo"]

	// Version channel, see registry.#Resolve.
	channel: *"fast" | "stable"

	release: {
		// Merge release PRs automatically once CI is green.
		autoMerge: *false | bool
	}

	network: {
		// Primary family first; pod/service CIDRs must match Talos KubeNetworkConfig.
		podCIDRs!: [...string]
		serviceCIDRs!: [...string]
		// Host interfaces Cilium attaches to.
		devices!: [...string]
	}

	storage: {
		// Host path of the Talos user volume backing local-path PVs.
		localPath: *"/var/mnt/local-storage" | string
	}
}
