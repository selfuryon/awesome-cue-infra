@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package cilium

import (
	"strings"
	"github.com/selfuryon/awesome-cue-infra/apps"
)

// Cilium on Talos: native routing, netkit, eBPF host routing and
// masquerading, kube-proxy replacement through KubePrism, LoadBalancer IPs
// from node addresses (node IPAM). IP families follow the cluster's pod CIDRs.
#Cilium: {
	#cluster: apps.#Cluster
	#version: string

	let _v4 = [for c in #cluster.network.podCIDRs if !strings.Contains(c, ":") {c}]
	let _v6 = [for c in #cluster.network.podCIDRs if strings.Contains(c, ":") {c}]

	component: apps.#Component & {
		name:      "cilium"
		namespace: "kube-system"
		chart: {
			kind:    "helm"
			url:     "https://helm.cilium.io"
			name:    "cilium"
			version: #version
		}
		values: {
			ipv4: enabled: len(_v4) > 0
			ipv6: enabled: len(_v6) > 0

			ipam: mode: "kubernetes"
			k8s: {
				requireIPv4PodCIDR: len(_v4) > 0
				requireIPv6PodCIDR: len(_v6) > 0
			}

			routingMode: "native"
			if len(_v4) > 0 {
				ipv4NativeRoutingCIDR: _v4[0]
				enableIPv4Masquerade:  true
			}
			if len(_v6) > 0 {
				ipv6NativeRoutingCIDR: _v6[0]
				// Pod CIDR is ULA; Cilium prefers the node's public address.
				enableIPv6Masquerade: true
			}

			kubeProxyReplacement: true
			// KubePrism
			k8sServiceHost: "localhost"
			k8sServicePort: 7445

			devices: #cluster.network.devices

			bpf: {
				datapathMode:      "netkit"
				masquerade:        true
				hostLegacyRouting: false
			}

			nodeIPAM: enabled: true
			defaultLBServiceIPAM: "nodeipam"
			loadBalancer: acceleration: "disabled"

			operator: replicas: 1

			// Talos: cgroup v2 is already mounted, SYS_MODULE is not allowed.
			cgroup: {
				autoMount: enabled: false
				hostRoot: "/sys/fs/cgroup"
			}
			securityContext: capabilities: {
				ciliumAgent: ["CHOWN", "KILL", "NET_ADMIN", "NET_RAW", "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"]
				cleanCiliumState: ["NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"]
			}

			hubble: enabled:     false
			prometheus: enabled: false
		}
	}
}
