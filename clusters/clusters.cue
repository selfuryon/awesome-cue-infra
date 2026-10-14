@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package clusters

import (
	"github.com/selfuryon/awesome-cue-infra/apps"
	alpha01 "github.com/selfuryon/awesome-cue-infra/clusters/alpha-01:alpha01"
)

#Entry: {
	config: apps.#Cluster
	manifests: [string]: apps.#Manifests
	release: [string]:   apps.#Manifests
}

Clusters: [string]: #Entry

Clusters: "alpha-01": {
	config:    alpha01.config
	manifests: alpha01.manifests
	release:   alpha01.release
}
