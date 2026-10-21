module: "github.com/selfuryon/awesome-cue-infra@v0"
language: version: "v0.18.0"
deps: {
	"cue.dev/x/argo/cd@v0": {
		v:       "v0.7.0"
		default: true
	}
	"cue.dev/x/crd/fluxcd.io@v0": {
		v:       "v0.8.0"
		default: true
	}
	"cue.dev/x/k8s.io@v0": {
		v:       "v0.12.0"
		default: true
	}
}
