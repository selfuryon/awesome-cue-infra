package apps

import "strings"

// Namespace Argo CD runs in; its Applications live here.
#ArgoNamespace: "argo-system"

// Renders components into one manifest set per #Cluster.sets entry. A
// component's chart becomes a Flux source + HelmRelease or an Argo CD
// Application depending on its set's controller; its plain manifests land in
// the same set as-is.
#Render: {
	#components: #Components
	#sets: [string]: #Set

	let _all = #components
	let _sets = #sets

	out: [string]: #Manifests
	// Every set renders, even when empty.
	for name, _ in #sets {
		out: (name): {}
	}

	for _, c in #components {
		let _controller = _sets[c.set].controller

		out: (c.set): c.manifests

		if c.chart != _|_ if _controller == "flux" {
			out: (c.set): scoped: (c.namespace): (#FluxChart & {#c: c, #components: _all}).out
		}
		if c.chart != _|_ if _controller == "argo" {
			out: (c.set): scoped: (#ArgoNamespace): application: (c.name): (#ArgoChart & {#c: c}).out
		}
	}
}

#FluxChart: {
	#c:          #Component
	#components: #Components

	let _chart = #c.chart
	out: {
		if _chart.kind == "helm" {
			helmRepository: (#c.name): spec: {
				url:      _chart.url
				interval: "12h"
			}
			helmRelease: (#c.name): spec: chart: spec: {
				chart:     _chart.name
				version:   _chart.version
				interval:  "12h"
				sourceRef: {kind: "HelmRepository", name: #c.name}
			}
		}
		if _chart.kind == "oci" {
			ociRepository: (#c.name): spec: {
				url: "\(_chart.url)/\(_chart.name)"
				ref: tag: _chart.version
				interval: "12h"
				layerSelector: {
					mediaType: "application/vnd.cncf.helm.chart.content.v1.tar+gzip"
					operation: "copy"
				}
			}
			helmRelease: (#c.name): spec: chartRef: {kind: "OCIRepository", name: #c.name}
		}
		if _chart.kind == "git" {
			gitRepository: (#c.name): spec: {
				url: _chart.url
				ref: tag: _chart.version
				interval: "12h"
			}
			helmRelease: (#c.name): spec: chart: spec: {
				chart:             _chart.path
				interval:          "12h"
				reconcileStrategy: "Revision"
				sourceRef:         {kind: "GitRepository", name: #c.name}
			}
		}

		helmRelease: (#c.name): spec: {
			releaseName: #c.name
			interval:    "1h"
			install: crds: "CreateReplace"
			upgrade: crds: "CreateReplace"
			values: #c.values
			if len(#c.dependsOn) > 0 {
				dependsOn: [for d in #c.dependsOn {
					name:      d
					namespace: #components[d].namespace
				}]
			}
			if len(#c.postRenderPatches) > 0 {
				postRenderers: [{kustomize: patches: #c.postRenderPatches}]
			}
		}
	}
}

#ArgoChart: {
	#c: #Component

	let _chart = #c.chart
	out: spec: {
		project: "default"
		source: {
			if _chart.kind == "helm" {
				repoURL:        _chart.url
				chart:          _chart.name
				targetRevision: _chart.version
			}
			if _chart.kind == "oci" {
				// Argo CD takes OCI Helm repositories without the scheme.
				repoURL:        strings.TrimPrefix(_chart.url, "oci://")
				chart:          _chart.name
				targetRevision: _chart.version
			}
			if _chart.kind == "git" {
				repoURL:        _chart.url
				path:           _chart.path
				targetRevision: _chart.version
			}
			helm: {
				releaseName:  #c.name
				valuesObject: #c.values
			}
		}
		destination: {
			server:    "https://kubernetes.default.svc"
			namespace: #c.namespace
		}
		syncPolicy: {
			automated:   {prune: true, selfHeal: true}
			syncOptions: ["ServerSideApply=true"]
		}
	}
}
