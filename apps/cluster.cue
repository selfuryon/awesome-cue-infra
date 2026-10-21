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

	// Component sets. Each set is its own project: one OCI artifact
	// (<cluster>-<set>), one entry in releases.json, released and rolled back
	// independently. The set's controller decides how its components are
	// wrapped and who applies the artifact.
	sets: [string]: #Set

	// Publish artifacts and open release PRs. Off for clusters that exist only
	// as manifests (rendered and diffed in PRs, never deployed).
	publish: *true | bool

	// Version channel, see registry.#Resolve.
	channel: *"fast" | "stable"

	release: {
		// Merge release PRs automatically once CI is green.
		autoMerge: *false | bool
	}

	network: {
		// Primary family first; pod/service CIDRs must match Talos KubeNetworkConfig.
		podCIDRs!:     [...string]
		serviceCIDRs!: [...string]
		// Host interfaces Cilium attaches to.
		devices!: [...string]
		// Sources allowed to reach the node itself (Talos API, kube-apiserver,
		// DHCP, ICMP) through the Cilium host firewall; everything else from
		// outside the cluster is dropped.
		trustedCIDRs!: [...string]
		// Cilium policyAuditMode: policies only log what they would drop. Used to
		// roll out the host firewall and default-deny policies safely.
		policyAudit: *false | bool
	}

	security: {
		// Image registries pods may pull from (prefixes; enforced by Kyverno,
		// apps/security/podpolicy). Images must name their registry.
		allowedRegistries: *[
			"docker.io/",
			"ghcr.io/",
			"quay.io/",
			"registry.k8s.io/",
			"reg.kyverno.io/",
			"ecr-public.aws.com/",
		] | [...string]
	}

	storage: {
		// Host path of the Talos user volume backing local-path PVs.
		localPath: *"/var/mnt/local-storage" | string
	}
}

#Set: {
	// flux: Kustomization over the artifact, charts as HelmReleases
	// argo: Argo CD Application over the artifact, charts as Applications
	controller!: "flux" | "argo"

	// Sets that must be ready first. Flux sets map to Kustomization
	// dependsOn; Argo sets wait for the Flux sets they depend on.
	dependsOn: [...string]
}
