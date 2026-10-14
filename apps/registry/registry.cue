@extern(embed)
@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package registry

// Upstream versions of every component, kept current by Renovate
// (regex manager over latest.json, see .github/renovate.json).
_latest: _ @embed(file="latest.json")

#Versions: [string]: string

latest: #Versions & {
	for e in _latest.components {
		(e.name): e.version
	}
}
