package hostfirewall

import (
	"list"

	"github.com/selfuryon/awesome-cue-infra/apps"
)

// Cilium host firewall: a CiliumClusterwideNetworkPolicy selecting the nodes
// (nodeSelector) puts their host endpoint into ingress default-deny, so only
// what is listed here reaches the node itself. Egress from the node is left
// open. Needs `hostFirewall.enabled` in the Cilium values (apps/network/cilium).
//
// Service traffic (LoadBalancer/NodePort) is translated to the backend pods by
// Cilium before host policy applies; it is governed by the pods' policies.
//
// Lives in the `policy` set: the CRD comes with Cilium in `system`.
#HostFirewall: {
	#cluster: apps.#Cluster

	let _trusted = #cluster.network.trustedCIDRs

	component: apps.#Component & {
		name:      "host-firewall"
		namespace: "kube-system"
		set:       "policy"

		manifests: global: ciliumClusterwideNetworkPolicy: "host-firewall": spec: {
			description:  "Ingress to the nodes: in-cluster traffic, plus Talos API, kube-apiserver, DHCP and ICMP from trusted networks."
			nodeSelector: {}
			ingress: [
				// Pods, the node itself, other nodes and Cilium health checks
				// (kubelet, KubePrism, CoreDNS upstream, metrics, ...).
				{fromEntities: ["cluster", "health", "remote-node"]},
				// talosctl (apid) and kubectl.
				{
					fromCIDRSet: [for c in _trusted {cidr: c}]
					toPorts: [{
						ports: [
							{port: "50000", protocol: "TCP"},
							{port: "6443", protocol: "TCP"},
						]
					}]
				},
				// DHCPv4 offers/acks: the IPv4 address is leased.
				{
					fromCIDRSet: [for c in _trusted {cidr: c}]
					toPorts:     [{ports: [{port: "68", protocol: "UDP"}]}]
				},
				// Ping, and IPv6 neighbor discovery and router advertisements
				// (SLAAC addresses and the IPv6 default route), which arrive
				// from link-local addresses.
				{
					fromCIDRSet: [for c in list.Concat([_trusted, ["fe80::/10"]]) {cidr: c}]
					icmps: [{
						fields: [
							{family: "IPv4", type: 8},   // echo request
							{family: "IPv6", type: 128}, // echo request
							{family: "IPv6", type: 134}, // router advertisement
							{family: "IPv6", type: 135}, // neighbor solicitation
							{family: "IPv6", type: 136}, // neighbor advertisement
							{family: "IPv6", type: 137}, // redirect
						]
					}]
				},
			]
		}
	}
}
