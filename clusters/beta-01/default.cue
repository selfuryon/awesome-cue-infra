@extern(embed)
@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package beta01

import (
	"github.com/selfuryon/awesome-cue-infra/apps"
	"github.com/selfuryon/awesome-cue-infra/apps/registry"
	app_flux "github.com/selfuryon/awesome-cue-infra/apps/gitops/flux"
	app_cilium "github.com/selfuryon/awesome-cue-infra/apps/network/cilium"
	app_argocd "github.com/selfuryon/awesome-cue-infra/apps/gitops/argocd"
	app_whoami "github.com/selfuryon/awesome-cue-infra/apps/examples/whoami"
)

// Manifest-only test cluster: rendered and diffed in PRs, never published or
// deployed. Shows a different component set (no cert-manager/local-path), an
// IPv4-only network and the stable channel with older pinned versions.
config: apps.#Cluster & {
	name:    "beta-01"
	channel: "stable"
	publish: false
	network: {
		podCIDRs: ["10.244.0.0/16"]
		serviceCIDRs: ["10.96.0.0/12"]
		devices: ["eth0"]
	}
}

// Stable channel: versions come only from pins.json (see the Promote workflow).
_pins: _ @embed(file="pins.json")
versions: (registry.#Resolve & {
	#channel: config.channel
	#pins:    _pins
}).out
let _v = versions

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
	"argo-cd": (app_argocd.#ArgoCD & {
		#cluster: config
		#version: _v["argo-cd"]
	}).component
	whoami: (app_whoami.#Whoami & {
		#cluster: config
		#version: _v.whoami
	}).component
}

// Overrides: two replicas of the example app.
components: whoami: manifests: scoped: whoami: deployment: whoami: spec: replicas: 2

_render: apps.#Render & {#components: components}

_releases: _ @embed(file="releases.json")
_release: apps.#Release & {
	#cluster: config
	#pins:    _releases
}

manifests: {
	bootstrap: components["flux-operator"].manifests
	flux:      _render.flux
	argo:      _render.argo
}

release: {
	flux: _release.flux
	argo: _release.argo
}
