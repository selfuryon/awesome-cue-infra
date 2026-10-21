package clusters

import (
	"github.com/selfuryon/awesome-cue-infra/apps"
	"github.com/selfuryon/awesome-cue-infra/apps/registry"
	alpha01 "github.com/selfuryon/awesome-cue-infra/clusters/alpha-01:alpha01"
	beta01 "github.com/selfuryon/awesome-cue-infra/clusters/beta-01:beta01"
)

#Entry: {
	config:   apps.#Cluster
	versions: registry.#Versions
	manifests: [string]: apps.#Manifests
	release: [string]:   apps.#Manifests
	...
}

Clusters: [string]: #Entry

Clusters: "alpha-01": alpha01.cluster
Clusters: "beta-01":  beta01.cluster
