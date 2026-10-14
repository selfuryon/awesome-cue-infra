@extern(embed)
@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package bundles

import (
	"github.com/selfuryon/awesome-cue-infra/apps"
	"github.com/selfuryon/awesome-cue-infra/apps/registry"
	base_flux "github.com/selfuryon/awesome-cue-infra/apps/base/flux"
	base_cilium "github.com/selfuryon/awesome-cue-infra/apps/base/cilium"
	base_certmanager "github.com/selfuryon/awesome-cue-infra/apps/base/certmanager"
	base_localpath "github.com/selfuryon/awesome-cue-infra/apps/base/localpath"
	base_argocd "github.com/selfuryon/awesome-cue-infra/apps/base/argocd"
	base_whoami "github.com/selfuryon/awesome-cue-infra/apps/base/whoami"
)

// Version channels.
//   flex:   follows apps/registry/latest.json (Renovate, auto-merged)
//   stable: pinned in stable.json, promoted from flex by the Promote workflow
flex:    registry.latest
_stable: _ @embed(file="stable.json")
stable:  registry.#Versions & _stable

// Resolves a channel with per-cluster pins on top: a pin wins over the
// channel's version, everything else follows the channel.
#Versions: {
	#channel: registry.#Versions
	#pins:    registry.#Versions

	out: registry.#Versions & {
		for name, v in #channel {
			(name): *v | string
		}
	} & #pins
}

// The homelab bundle: the platform (Flux) and the example user app (Argo).
#Homelab: {
	#cluster:  apps.#Cluster
	#versions: registry.#Versions

	let _c = #cluster
	let _v = #versions

	components: apps.#Components & {
		"flux-operator": (base_flux.#Flux & {
			#cluster: _c
			#versions: {
				operator: _v["flux-operator"]
				flux:     _v.flux
			}
		}).component
		cilium: (base_cilium.#Cilium & {
			#cluster: _c
			#version: _v.cilium
		}).component
		"cert-manager": (base_certmanager.#CertManager & {
			#cluster: _c
			#version: _v["cert-manager"]
		}).component
		"local-path-provisioner": (base_localpath.#LocalPath & {
			#cluster: _c
			#version: _v["local-path-provisioner"]
		}).component
		"argo-cd": (base_argocd.#ArgoCD & {
			#cluster: _c
			#version: _v["argo-cd"]
		}).component
		whoami: (base_whoami.#Whoami & {
			#cluster: _c
			#version: _v.whoami
		}).component
	}
}
