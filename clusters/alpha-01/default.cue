@extern(embed)
@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package alpha01

import (
	"github.com/selfuryon/awesome-cue-infra/apps"
	"github.com/selfuryon/awesome-cue-infra/apps/registry"
	app_flux "github.com/selfuryon/awesome-cue-infra/apps/flux"
	app_cilium "github.com/selfuryon/awesome-cue-infra/apps/cilium"
	app_certmanager "github.com/selfuryon/awesome-cue-infra/apps/certmanager"
	app_localpath "github.com/selfuryon/awesome-cue-infra/apps/localpath"
	app_argocd "github.com/selfuryon/awesome-cue-infra/apps/argocd"
	app_whoami "github.com/selfuryon/awesome-cue-infra/apps/whoami"
)

// Single-node Talos cluster on a Beelink U59 behind Starlink.
// Talos machine config lives in ./talos (see talos/gen.sh).
config: apps.#Cluster & {
	name:    "alpha-01"
	channel: "fast"
	release: autoMerge: true
	network: {
		// Dual-stack, IPv6 primary; must match talos/patches/node.yaml.
		podCIDRs: ["fd00:10:244::/56", "10.244.0.0/16"]
		serviceCIDRs: ["fd00:10:96::/112", "10.96.0.0/12"]
		devices: ["enp2s0"]
	}
}

// Component versions: the channel's versions with pins.json on top.
_pins: _ @embed(file="pins.json")
let _v = (registry.#Resolve & {
	#channel: config.channel
	#pins:    _pins
}).out

components: apps.#Components & {
	"flux-operator": (app_flux.#Flux & {
		#cluster: config
		#versions: {
			operator: _v["flux-operator"]
			flux:     _v.flux
		}
	}).component
	cilium: (app_cilium.#Cilium & {
		#cluster: config
		#version: _v.cilium
	}).component
	"cert-manager": (app_certmanager.#CertManager & {
		#cluster: config
		#version: _v["cert-manager"]
	}).component
	"local-path-provisioner": (app_localpath.#LocalPath & {
		#cluster: config
		#version: _v["local-path-provisioner"]
	}).component
	"argo-cd": (app_argocd.#ArgoCD & {
		#cluster: config
		#version: _v["argo-cd"]
	}).component
	whoami: (app_whoami.#Whoami & {
		#cluster: config
		#version: _v.whoami
	}).component
}

// Cluster-specific overrides go here, e.g.:
//   components: cilium: values: hubble: enabled: true

_render: apps.#Render & {#components: components}

// Artifact versions the cluster runs; updated by release PRs.
_releases: _ @embed(file="releases.json")
_release: apps.#Release & {
	#cluster: config
	#pins:    _releases
}

// Projects rendered by `cue cmd dump`:
//   bootstrap: applied by hand once (flux-system namespace + FluxInstance)
//   flux, argo: published as OCI artifacts
manifests: {
	bootstrap: components["flux-operator"].manifests
	flux:      _render.flux
	argo:      _render.argo
}

// Release layer committed to ./release (`cue cmd write-release`).
release: {
	flux: _release.flux
	argo: _release.argo
}
