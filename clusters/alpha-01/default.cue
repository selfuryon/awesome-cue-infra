@extern(embed)
@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package alpha01

import "github.com/selfuryon/awesome-cue-infra/clusters:defaults"

_pins:     _ @embed(file="pins.json")
_releases: _ @embed(file="releases.json")

// Single-node Talos cluster on a Beelink U59 behind Starlink.
// Talos machine config lives in ./talos (see talos/gen.sh).
cluster: defaults.#Homelab & {
	config: {
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
	#pins:     _pins
	#releases: _releases
}

// Cluster-specific overrides go here, e.g.:
//   cluster: components: cilium: values: hubble: enabled: true
