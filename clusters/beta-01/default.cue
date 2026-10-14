@extern(embed)
@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package beta01

import (
	"github.com/selfuryon/awesome-cue-infra/clusters:defaults"
	app_whoami "github.com/selfuryon/awesome-cue-infra/apps/examples/whoami"
)

_pins:     _ @embed(file="pins.json")
_releases: _ @embed(file="releases.json")

// Manifest-only test cluster: rendered and diffed in PRs, never published or
// deployed. Shows a different component set (core + the example app), an
// IPv4-only network and the stable channel with older pinned versions.
cluster: defaults.#Core & {
	config: {
		name:    "beta-01"
		channel: "stable"
		publish: false
		network: {
			podCIDRs: ["10.244.0.0/16"]
			serviceCIDRs: ["10.96.0.0/12"]
			devices: ["eth0"]
		}
	}
	#pins:     _pins
	#releases: _releases
}

// An extra component on top of #Core.
cluster: components: whoami: (app_whoami.#Whoami & {
	#cluster: cluster.config
	#version: cluster.versions.whoami
}).component

// Overrides: two replicas of the example app.
cluster: components: whoami: manifests: scoped: whoami: deployment: whoami: spec: replicas: 2
