@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package defaults

import (
	"github.com/selfuryon/awesome-cue-infra/apps"
	"github.com/selfuryon/awesome-cue-infra/apps/registry"
	app_flux "github.com/selfuryon/awesome-cue-infra/apps/gitops/flux"
	app_argocd "github.com/selfuryon/awesome-cue-infra/apps/gitops/argocd"
	app_cilium "github.com/selfuryon/awesome-cue-infra/apps/network/cilium"
	app_certmanager "github.com/selfuryon/awesome-cue-infra/apps/security/certmanager"
	app_kyverno "github.com/selfuryon/awesome-cue-infra/apps/security/kyverno"
	app_localpath "github.com/selfuryon/awesome-cue-infra/apps/storage/localpath"
	app_whoami "github.com/selfuryon/awesome-cue-infra/apps/examples/whoami"
)

// Everything a cluster needs besides its config, components and inputs:
// version resolution, rendering, release layer and projects. A cluster
// unifies one of the definitions below with its config, pins and releases,
// then adds components or overrides values on top:
//
//   cluster: defaults.#Homelab & {config: {...}, #pins: _pins, #releases: _releases}
//   cluster: components: cilium: values: hubble: enabled: true
//
// Components cannot be removed by unification; start from the smallest
// definition that fits and add the rest.
#Cluster: {
	config: apps.#Cluster

	// Default sets: platform components through Flux, user applications
	// through Argo CD (which the system set installs). Clusters may add more.
	config: sets: {
		system: controller: "flux"
		apps: {
			controller: "argo"
			dependsOn: ["system"]
		}
		// `bootstrap` is the hand-applied project, not a set.
		bootstrap?: _|_
	}

	// clusters/<name>/pins.json and releases.json
	#pins: registry.#Versions
	#releases: {...}

	let _pins = #pins
	versions: (registry.#Resolve & {
		#channel: config.channel
		#pins:    _pins
	}).out

	components: apps.#Components

	let _render = apps.#Render & {
		#components: components
		#sets:       config.sets
	}
	let _release = apps.#Release & {
		#cluster: config
		#pins:    #releases
	}

	// Projects rendered by `cue cmd dump`:
	//   bootstrap: applied by hand once (flux-system namespace + FluxInstance)
	//   <set>:     one per config.sets entry, published as OCI artifacts
	manifests: {
		bootstrap: components["flux-operator"].manifests
		_render.out
	}

	// Release layer committed to clusters/<name>/release (`cue cmd write-release`).
	release: {
		flux: _release.flux
		argo: _release.argo
	}
}

// Minimal platform: Flux (with flux-operator), Cilium and headless Argo CD.
#Core: #Cluster & {
	// Bring the fields into lexical scope for the references below.
	config:   _
	versions: _

	components: {
		"flux-operator": (app_flux.#Flux & {
			#cluster: config
			#versions: {
				operator: versions["flux-operator"]
				flux:     versions.flux
			}
		}).component
		cilium: (app_cilium.#Cilium & {
			#cluster: config
			#version: versions.cilium
		}).component
		"argo-cd": (app_argocd.#ArgoCD & {
			#cluster: config
			#version: versions["argo-cd"]
		}).component
	}
}

// Core plus certificates, policies (Kyverno), local storage and the example
// Argo application.
#Homelab: #Core & {
	config:   _
	versions: _

	components: {
		"cert-manager": (app_certmanager.#CertManager & {
			#cluster: config
			#version: versions["cert-manager"]
		}).component
		kyverno: (app_kyverno.#Kyverno & {
			#cluster: config
			#version: versions.kyverno
		}).component
		"local-path-provisioner": (app_localpath.#LocalPath & {
			#cluster: config
			#version: versions["local-path-provisioner"]
		}).component
		whoami: (app_whoami.#Whoami & {
			#cluster: config
			#version: versions.whoami
		}).component
	}
}
