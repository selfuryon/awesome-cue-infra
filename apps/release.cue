@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package apps

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
//   release/flux: OCIRepository + Kustomization for the Flux artifact, and a
//                 Kustomization that applies release/argo once Flux is ready.
//   release/argo: the root Argo CD Application for the Argo artifact.
#Release: {
	#cluster: #Cluster
	#pins: {
		flux?: #Pin
		argo?: #Pin
	}

	let _name = #cluster.name
	let _ns = "flux-system"

	flux: #Manifests
	argo: #Manifests

	// Always present, so the sync path is never empty and the deployed
	// versions are visible in-cluster.
	flux: scoped: (_ns): configMap: "\(_name)-release": data: {
		for project, pin in #pins {
			(project): "\(pin.tag)@\(pin.digest)"
		}
	}

	if #pins.flux != _|_ {
		flux: scoped: (_ns): {
			ociRepository: "\(_name)-flux": spec: {
				url: "oci://\(#Repo.registry)/\(_name)-flux"
				ref: digest: #pins.flux.digest
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
			kustomization: "\(_name)-flux": spec: {
				sourceRef: {kind: "OCIRepository", name: "\(_name)-flux"}
				path:     "./"
				interval: "10m"
				timeout:  "10m"
				prune:    true
				wait:     true
				decryption: {
					provider: "sops"
					secretRef: name: "sops-age"
				}
			}
		}
	}

	if #pins.argo != _|_ {
		flux: scoped: (_ns): kustomization: "\(_name)-argo": spec: {
			// The GitRepository created by the FluxInstance sync.
			sourceRef: {kind: "GitRepository", name: _ns}
			path:     "./clusters/\(_name)/release/argo"
			interval: "10m"
			prune:    true
			if #pins.flux != _|_ {
				dependsOn: [{name: "\(_name)-flux"}]
			}
		}

		argo: scoped: (#ArgoNamespace): application: "\(_name)-apps": spec: {
			project: "default"
			source: {
				repoURL:        "oci://\(#Repo.registry)/\(_name)-argo"
				targetRevision: #pins.argo.digest
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
