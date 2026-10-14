@extern(embed)
@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package alpha01

import (
	"github.com/selfuryon/awesome-cue-infra/apps"
	"github.com/selfuryon/awesome-cue-infra/apps/bundles"
)

// Single-node Talos cluster on a Beelink U59 behind Starlink.
// Talos machine config lives in ./talos (see talos/gen.sh).
config: apps.#Cluster & {
	name: "alpha-01"
	release: autoMerge: true
	network: {
		// Dual-stack, IPv6 primary; must match talos/patches/node.yaml.
		podCIDRs: ["fd00:10:244::/56", "10.244.0.0/16"]
		serviceCIDRs: ["fd00:10:96::/112", "10.96.0.0/12"]
		devices: ["enp2s0"]
	}
}

// Versions: the flex channel, with per-cluster pins on top.
_versions: (bundles.#Versions & {
	#channel: bundles.flex
	#pins: {}
}).out

_bundle: bundles.#Homelab & {
	#cluster:  config
	#versions: _versions
}

// Cluster-specific overrides go here, e.g.:
//   _bundle: components: cilium: values: hubble: enabled: true

_render: apps.#Render & {#components: _bundle.components}

// Artifact versions the cluster runs; updated by release PRs.
_pins: _ @embed(file="releases.json")
_release: apps.#Release & {
	#cluster: config
	#pins:    _pins
}

// Projects rendered by `cue cmd dump`:
//   bootstrap: applied by hand once (flux-system namespace + FluxInstance)
//   flux, argo: published as OCI artifacts
manifests: {
	bootstrap: _bundle.components["flux-operator"].manifests
	flux:      _render.flux
	argo:      _render.argo
}

// Release layer committed to ./release (`cue cmd write-release`).
release: {
	flux: _release.flux
	argo: _release.argo
}
