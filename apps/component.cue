@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package apps

// A Helm chart source. The same definition renders to a Flux source +
// HelmRelease or to an Argo CD Application, depending on the controller.
#Chart: {
	// helm: classic HTTP Helm repository
	// oci:  chart stored as an OCI artifact (url without the chart name)
	// git:  chart inside a Git repository (path to the chart directory)
	kind!:    "helm" | "oci" | "git"
	url!:     string
	name!:    string
	version!: string
	if kind == "git" {
		path!: string
	}
}

// A deployable unit of the platform or of user applications.
#Component: {
	name!:      string
	namespace!: string

	// The set (project/artifact) the component lands in, see #Cluster.sets.
	// Its controller decides the wrapper: Flux source + HelmRelease, or an
	// Argo CD Application.
	set: *"system" | string

	// Optional Helm chart and its values.
	chart?: #Chart
	values: {...}

	// Names of Flux-delivered components that must be ready first.
	// Honoured by Flux; Argo applies everything in one sync.
	dependsOn: [...string]

	// Flux HelmRelease post-renderer patches (kustomize patches).
	postRenderPatches: [...{...}]

	// Plain manifests shipped next to the chart (namespace, CRs, ...).
	manifests: #Manifests
}

#Components: [string]~(ID,_): #Component & {name: *ID | string}
