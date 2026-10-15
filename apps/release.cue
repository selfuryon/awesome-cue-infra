@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package apps

import "list"

// A published artifact version (see clusters/<name>/releases.json).
#Pin: {
	tag!:    string
	digest!: =~"^sha256:[0-9a-f]{64}$"
}

// The release layer: the only place that points a cluster at artifact
// versions. It is committed to Git (clusters/<name>/release/) and synced by
// the FluxInstance, so switching versions is a PR that edits releases.json —
// artifacts never reference themselves and never use `latest`.
//
// One entry per set (releases.json key = set name, artifact <cluster>-<set>):
//   release/flux: per Flux set an OCIRepository + Kustomization (dependsOn
//                 follows the set's dependsOn), plus a Kustomization applying
//                 release/argo once the Flux sets the Argo sets need are ready.
//   release/argo: per Argo set an Application over its artifact.
#Release: {
	#cluster: #Cluster
	#pins: [string]: #Pin

	let _name = #cluster.name
	let _ns = "flux-system"
	let _sets = #cluster.sets
	let _pins = #pins

	// Pinned sets by controller (sets without a release yet are skipped).
	let _flux = [for s, _ in _pins if _sets[s] != _|_ if _sets[s].controller == "flux" {s}]
	let _argo = [for s, _ in _pins if _sets[s] != _|_ if _sets[s].controller == "argo" {s}]

	flux: #Manifests
	argo: #Manifests

	// Always present, so the sync path is never empty and the deployed
	// versions are visible in-cluster.
	flux: scoped: (_ns): configMap: "\(_name)-release": data: {
		for set, pin in _pins {
			(set): "\(pin.tag)@\(pin.digest)"
		}
	}

	for set in _flux {
		flux: scoped: (_ns): {
			ociRepository: "\(_name)-\(set)": spec: {
				url: "oci://\(#Repo.registry)/\(_name)-\(set)"
				ref: digest: _pins[set].digest
				interval: "10m"
				layerSelector: {
					mediaType: "application/vnd.oci.image.layer.v1.tar+gzip"
					operation: "extract"
				}
				verify: {
					provider: "cosign"
					matchOIDCIdentity: [{
						issuer:  #Repo.signer.issuer
						subject: #Repo.signer.subject
					}]
				}
			}
			kustomization: "\(_name)-\(set)": spec: {
				sourceRef: {kind: "OCIRepository", name: "\(_name)-\(set)"}
				path:     "./"
				interval: "10m"
				timeout:  "10m"
				prune:    true
				wait:     true
				decryption: {
					provider: "sops"
					secretRef: name: "sops-age"
				}
				let _deps = [for d in _sets[set].dependsOn if list.Contains(_flux, d) {name: "\(_name)-\(d)"}]
				if len(_deps) > 0 {
					dependsOn: _deps
				}
			}
		}
	}

	if len(_argo) > 0 {
		// Flux sets any Argo set depends on.
		let _needed = [for s in _flux if list.Contains(list.Concat([for a in _argo {_sets[a].dependsOn}]), s) {s}]

		flux: scoped: (_ns): kustomization: "\(_name)-release-argo": spec: {
			// The GitRepository created by the FluxInstance sync.
			sourceRef: {kind: "GitRepository", name: _ns}
			path:     "./clusters/\(_name)/release/argo"
			interval: "10m"
			prune:    true
			if len(_needed) > 0 {
				dependsOn: [for s in _needed {name: "\(_name)-\(s)"}]
			}
		}
	}

	for set in _argo {
		argo: scoped: (#ArgoNamespace): application: "\(_name)-\(set)": spec: {
			project: "default"
			source: {
				repoURL:        "oci://\(#Repo.registry)/\(_name)-\(set)"
				targetRevision: _pins[set].digest
				path:           "."
			}
			destination: {
				server:    "https://kubernetes.default.svc"
				namespace: #ArgoNamespace
			}
			syncPolicy: {
				automated: {prune: true, selfHeal: true}
				syncOptions: ["ServerSideApply=true"]
			}
		}
	}
}
