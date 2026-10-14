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

// Versions a cluster runs, from its channel and pins (clusters/<name>/pins.json):
//   fast:   latest.json, with pins on top (Renovate updates roll out directly)
//   stable: pins only; every component the cluster uses must be pinned
#Resolve: {
	#channel: "fast" | "stable"
	#pins:    #Versions

	out: #Versions
	if #channel == "fast" {
		out: {
			for name, v in latest {
				(name): *v | string
			}
		} & #pins
	}
	if #channel == "stable" {
		out: #pins
	}
}
