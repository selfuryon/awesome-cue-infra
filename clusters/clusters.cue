@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

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
}

Clusters: [string]: #Entry

Clusters: "alpha-01": {
	config:    alpha01.config
	versions:  alpha01.versions
	manifests: alpha01.manifests
	release:   alpha01.release
}

Clusters: "beta-01": {
	config:    beta01.config
	versions:  beta01.versions
	manifests: beta01.manifests
	release:   beta01.release
}
