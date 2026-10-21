package v2

#CiliumNetworkPolicy: {

	// APIVersion defines the versioned schema of this representation of an object.
	// Servers should convert recognized schemas to the latest internal value, and
	// may reject unrecognized values.
	// More info:
	// https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources
	apiVersion?: string

	// Kind is a string value representing the REST resource this object represents.
	// Servers may infer this from the endpoint the client submits requests to.
	// Cannot be updated.
	// In CamelCase.
	// More info:
	// https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
	kind?:     string
	metadata!: {}

	// Spec is the desired Cilium specific rule specification.
	spec?: {
		// Description is a free form string, it can be used by the creator of
		// the rule to store human readable explanation of the purpose of this
		// rule. Rules cannot be identified by comment.
		description?: string

		// Egress is a list of EgressRule which are enforced at egress.
		// If omitted or empty, this rule does not apply at egress.
		egress?: [...{
			// Authentication is the required authentication type for the allowed traffic, if any.
			authentication?: {
				// Mode is the required authentication mode for the allowed traffic, if any.
				mode!: "disabled" | "required" | "test-always-fail"
			}

			// ICMPs is a list of ICMP rule identified by type number
			// which the endpoint subject to the rule is allowed to connect to.
			//
			// Example:
			// Any endpoint with the label "app=httpd" is allowed to initiate
			// type 8 ICMP connections.
			icmps?: [...{
				// Fields is a list of ICMP fields.
				fields?: [...{
					// Family is a IP address version.
					// Currently, we support `IPv4` and `IPv6`.
					// `IPv4` is set as default.
					family?: "IPv4" | "IPv6"

					// Type is a ICMP-type.
					// It should be an 8bit code (0-255), or it's CamelCase name (for example, "EchoReply").
					// Allowed ICMP types are:
					// Ipv4: EchoReply | DestinationUnreachable | Redirect | Echo | EchoRequest |
					// RouterAdvertisement | RouterSelection | TimeExceeded | ParameterProblem |
					// Timestamp | TimestampReply | Photuris | ExtendedEcho Request | ExtendedEcho Reply
					// Ipv6: DestinationUnreachable | PacketTooBig | TimeExceeded | ParameterProblem |
					// EchoRequest | EchoReply | MulticastListenerQuery| MulticastListenerReport |
					// MulticastListenerDone | RouterSolicitation | RouterAdvertisement | NeighborSolicitation |
					// NeighborAdvertisement | RedirectMessage | RouterRenumbering | ICMPNodeInformationQuery |
					// ICMPNodeInformationResponse | InverseNeighborDiscoverySolicitation |
					// InverseNeighborDiscoveryAdvertisement |
					// HomeAgentAddressDiscoveryRequest | HomeAgentAddressDiscoveryReply | MobilePrefixSolicitation |
					// MobilePrefixAdvertisement | DuplicateAddressRequestCodeSuffix |
					// DuplicateAddressConfirmationCodeSuffix |
					// ExtendedEchoRequest | ExtendedEchoReply
					type!: (int |
						=~"^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]|EchoReply|DestinationUnreachable|Redirect|Echo|RouterAdvertisement|RouterSelection|TimeExceeded|ParameterProblem|Timestamp|TimestampReply|Photuris|ExtendedEchoRequest|ExtendedEcho Reply|PacketTooBig|ParameterProblem|EchoRequest|MulticastListenerQuery|MulticastListenerReport|MulticastListenerDone|RouterSolicitation|RouterAdvertisement|NeighborSolicitation|NeighborAdvertisement|RedirectMessage|RouterRenumbering|ICMPNodeInformationQuery|ICMPNodeInformationResponse|InverseNeighborDiscoverySolicitation|InverseNeighborDiscoveryAdvertisement|HomeAgentAddressDiscoveryRequest|HomeAgentAddressDiscoveryReply|MobilePrefixSolicitation|MobilePrefixAdvertisement|DuplicateAddressRequestCodeSuffix|DuplicateAddressConfirmationCodeSuffix)$")
				}]
			}]

			// ToCIDR is a list of IP blocks which the endpoint subject to the rule
			// is allowed to initiate connections. Only connections destined for
			// outside of the cluster and not targeting the host will be subject
			// to CIDR rules. This will match on the destination IP address of
			// outgoing connections. Adding a prefix into ToCIDR or into ToCIDRSet
			// with no ExcludeCIDRs is equivalent. Overlaps are allowed between
			// ToCIDR and ToCIDRSet.
			//
			// Example:
			// Any endpoint with the label "app=database-proxy" is allowed to
			// initiate connections to 10.2.3.0/24
			toCIDR?: [...string]

			// ToCIDRSet is a list of IP blocks which the endpoint subject to the rule
			// is allowed to initiate connections to in addition to connections
			// which are allowed via ToEndpoints, along with a list of subnets contained
			// within their corresponding IP block to which traffic should not be
			// allowed. This will match on the destination IP address of outgoing
			// connections. Adding a prefix into ToCIDR or into ToCIDRSet with no
			// ExcludeCIDRs is equivalent. Overlaps are allowed between ToCIDR and
			// ToCIDRSet.
			//
			// Example:
			// Any endpoint with the label "app=database-proxy" is allowed to
			// initiate connections to 10.2.3.0/24 except from IPs in subnet 10.2.3.0/28.
			toCIDRSet?: [...{
				// CIDR is a CIDR prefix / IP Block.
				cidr?: string

				// CIDRGroupRef is a reference to a CiliumCIDRGroup object.
				// A CiliumCIDRGroup contains a list of CIDRs that the endpoint, subject to
				// the rule, can (Ingress/Egress) or cannot (IngressDeny/EgressDeny) receive
				// connections from.
				cidrGroupRef?: =~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"

				// CIDRGroupSelector selects CiliumCIDRGroups by their labels,
				// rather than by name.
				cidrGroupSelector?: {
					// matchExpressions is a list of label selector requirements. The requirements are ANDed.
					matchExpressions?: [...{
						// key is the label key that the selector applies to.
						key!: string

						// operator represents a key's relationship to a set of values.
						// Valid operators are In, NotIn, Exists and DoesNotExist.
						operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

						// values is an array of string values. If the operator is In or NotIn,
						// the values array must be non-empty. If the operator is Exists or DoesNotExist,
						// the values array must be empty. This array is replaced during a strategic
						// merge patch.
						values?: [...string]
					}]

					// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
					// map is equivalent to an element of matchExpressions, whose key field is "key", the
					// operator is "In", and the values array contains only "value". The requirements are ANDed.
					matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
				}

				// ExceptCIDRs is a list of IP blocks which the endpoint subject to the rule
				// is not allowed to initiate connections to. These CIDR prefixes should be
				// contained within Cidr, using ExceptCIDRs together with CIDRGroupRef is not
				// supported yet.
				// These exceptions are only applied to the Cidr in this CIDRRule, and do not
				// apply to any other CIDR prefixes in any other CIDRRules.
				except?: [...string]
			}]

			// ToEndpoints is a list of endpoints identified by an EndpointSelector to
			// which the endpoints subject to the rule are allowed to communicate.
			//
			// Example:
			// Any endpoint with the label "role=frontend" can communicate with any
			// endpoint carrying the label "role=backend".
			//
			// Note that while an empty non-nil ToEndpoints does not select anything,
			// nil ToEndpoints is implicitly treated as a wildcard selector if ToPorts
			// are also specified.
			// To select everything, use one EndpointSelector without any match requirements.
			toEndpoints?: [...{
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
			}]

			// ToEntities is a list of special entities to which the endpoint subject
			// to the rule is allowed to initiate connections. Supported entities are
			// `world`, `cluster`, `cluster-mesh`, `host`, `remote-node`, `kube-apiserver`, `ingress`, `init`,
			// `health`, `unmanaged`, `none` and `all`.
			toEntities?: [
				..."all" |
					"world" |
					"cluster" |
					"cluster-mesh" |
					"host" |
					"init" |
					"ingress" |
					"unmanaged" |
					"remote-node" |
					"health" |
					"none" |
					"kube-apiserver",
			]

			// ToFQDN allows whitelisting DNS names in place of IPs. The IPs that result
			// from DNS resolution of `ToFQDN.MatchName`s are added to the same
			// EgressRule object as ToCIDRSet entries, and behave accordingly. Any L4 and
			// L7 rules within this EgressRule will also apply to these IPs.
			// The DNS -> IP mapping is re-resolved periodically from within the
			// cilium-agent, and the IPs in the DNS response are effected in the policy
			// for selected pods as-is (i.e. the list of IPs is not modified in any way).
			// Note: An explicit rule to allow for DNS traffic is needed for the pods, as
			// ToFQDN counts as an egress rule and will enforce egress policy when
			// PolicyEnforcment=default.
			// Note: If the resolved IPs are IPs within the kubernetes cluster, the
			// ToFQDN rule will not apply to that IP.
			// Note: ToFQDN cannot occur in the same policy as other To* rules.
			toFQDNs?: [...{
				// MatchName matches literal DNS names. A trailing "." is automatically added
				// when missing.
				matchName?: =~"^([-a-zA-Z0-9_]+[.]?)+$"

				// MatchPattern allows using wildcards to match DNS names. All wildcards are
				// case insensitive. The wildcards are:
				// - "*" matches 0 or more DNS valid characters, and may occur anywhere in
				// the pattern. As a special case a "*" as the leftmost character, without a
				// following "." matches all subdomains as well as the name to the right.
				// A trailing "." is automatically added when missing.
				// - "**." is a special prefix which matches all multilevel subdomains in the prefix.
				//
				// Examples:
				// 1. `*.cilium.io` matches subdomains of cilium at that level
				// www.cilium.io and blog.cilium.io match, cilium.io and google.com do not
				// 2. `*cilium.io` matches cilium.io and all subdomains ends with "cilium.io"
				// except those containing "." separator, subcilium.io and sub-cilium.io match,
				// www.cilium.io and blog.cilium.io does not
				// 3. `sub*.cilium.io` matches subdomains of cilium where the subdomain component
				// begins with "sub". sub.cilium.io and subdomain.cilium.io match while www.cilium.io,
				// blog.cilium.io, cilium.io and google.com do not
				// 4. `**.cilium.io` matches all multilevel subdomains of cilium.io.
				// "app.cilium.io" and "test.app.cilium.io" match but not "cilium.io"
				matchPattern?: =~"^([-a-zA-Z0-9_*]+[.]?)+$"
			}]

			// ToGroups allows policies to reference CIDRs provided by external integrations.
			// Currently, only AWS is supported, and the rule can select by multiple sub directives.
			// ToGroups entries are functionally equivalent to toCIDR, and have the same
			// limitiations. They cannot select traffic originating from within the cluster.
			//
			// Example:
			// toGroups:
			// - aws:
			// securityGroupsIds:
			// - 'sg-XXXXXXXXXXXXX'
			toGroups?: [...{
				// AWSGroup is an structure that can be used to whitelisting information from AWS integration
				aws?: {
					// Labels selects AWS ENIs by labels.
					// Multiple labels are AND-ed together.
					labels?: [string]: string

					// Deprecated: Region is unused.
					region?: string

					// SecurityGroupsIds selects VPC SecurityGroups by IDs.
					// If multiple IDs are specified, they are OR-ed together.
					//
					// Note that this may be AND-ed with any Names specified. Specifying both
					// IDs and Names is not recommended.
					securityGroupsIds?: [...string]

					// SecurityGroupsNames selects VPC SecurityGroups by name.
					// If multiple names are specified, they are OR-ed together.
					//
					// Note that this may be AND-ed with any IDs specified. Specifying both
					// IDs and Names is not recommended.
					securityGroupsNames?: [...string]
				}
			}]

			// ToNodes is a list of nodes identified by an
			// EndpointSelector to which endpoints subject to the rule is allowed to communicate.
			toNodes?: [...{
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
			}]

			// ToPorts is a list of destination ports identified by port number and
			// protocol which the endpoint subject to the rule is allowed to
			// connect to.
			//
			// Example:
			// Any endpoint with the label "role=frontend" is allowed to initiate
			// connections to destination port 8080/tcp
			toPorts?: [...{
				// listener specifies the name of a custom Envoy listener to which this traffic should be
				// redirected to.
				listener?: {
					// EnvoyConfig is a reference to the CEC or CCEC resource in which
					// the listener is defined.
					envoyConfig!: {
						// Kind is the resource type being referred to. Defaults to CiliumEnvoyConfig or
						// CiliumClusterwideEnvoyConfig for CiliumNetworkPolicy and CiliumClusterwideNetworkPolicy,
						// respectively. The only case this is currently explicitly needed is when referring to a
						// CiliumClusterwideEnvoyConfig from CiliumNetworkPolicy, as using a namespaced listener
						// from a cluster scoped policy is not allowed.
						kind?: "CiliumEnvoyConfig" | "CiliumClusterwideEnvoyConfig"

						// Name is the resource name of the CiliumEnvoyConfig or CiliumClusterwideEnvoyConfig where
						// the listener is defined in.
						name!: string
					}

					// Name is the name of the listener.
					name!: string

					// Priority for this Listener that is used when multiple rules would apply different
					// listeners to a policy map entry. Behavior of this is implementation dependent.
					priority?: int & <=100 & >=1
				}

				// OriginatingTLS is the TLS context for the connections originated by
				// the L7 proxy. For egress policy this specifies the client-side TLS
				// parameters for the upstream connection originating from the L7 proxy
				// to the remote destination. For ingress policy this specifies the
				// client-side TLS parameters for the connection from the L7 proxy to
				// the local endpoint.
				originatingTLS?: {
					// Certificate is the file name or k8s secret item name for the certificate
					// chain. If omitted, 'tls.crt' is assumed, if it exists. If given, the
					// item must exist.
					certificate?: string

					// PrivateKey is the file name or k8s secret item name for the private key
					// matching the certificate chain. If omitted, 'tls.key' is assumed, if it
					// exists. If given, the item must exist.
					privateKey?: string

					// Secret is the secret that contains the certificates and private key for
					// the TLS context.
					// By default, Cilium will search in this secret for the following items:
					// - 'ca.crt' - Which represents the trusted CA to verify remote source.
					// - 'tls.crt' - Which represents the public key certificate.
					// - 'tls.key' - Which represents the private key matching the public key
					// certificate.
					secret!: {
						// Name is the name of the secret.
						name!: string

						// Namespace is the namespace in which the secret exists. Context of use
						// determines the default value if left out (e.g., "default").
						namespace?: string
					}

					// TrustedCA is the file name or k8s secret item name for the trusted CA.
					// If omitted, 'ca.crt' is assumed, if it exists. If given, the item must
					// exist.
					trustedCA?: string
				}

				// Ports is a list of L4 port/protocol
				ports?: [...{
					// EndPort can only be an L4 port number.
					endPort?: int32 & int & <=65535 & >=0

					// Port can be an L4 port number, or a name in the form of "http"
					// or "http-8080".
					port?:
						=~"^(6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[0-9]{1,4})|([a-zA-Z0-9]-?)*[a-zA-Z](-?[a-zA-Z0-9])*$"

					// Protocol is the L4 protocol. If "ANY", omitted or empty, any protocols
					// with transport ports (TCP, UDP, SCTP) match.
					//
					// Accepted values: "TCP", "UDP", "SCTP", "VRRP", "IGMP", "GRE", "IPIP",
					// "IPV6", "ESP", "AH", "ANY"
					//
					// Tunnel/encapsulation protocols (GRE, IPIP, IPV6, ESP, AH) and other
					// extended IP protocols (VRRP, IGMP) require the --enable-extended-ip-protocols
					// flag to be set. These protocols do not use transport-layer ports.
					//
					// Matching on ICMP is not supported.
					//
					// Named port specified for a container may narrow this down, but may not
					// contradict this.
					protocol?: "TCP" | "UDP" | "SCTP" | "VRRP" | "IGMP" | "GRE" | "IPIP" | "IPV6" | "ESP" | "AH" | "ANY"
				}]

				// Rules is a list of additional port level rules which must be met in
				// order for the PortRule to allow the traffic. If omitted or empty,
				// no layer 7 rules are enforced.
				rules?: {
					// DNS-specific rules.
					dns?: [...{
						// MatchName matches literal DNS names. A trailing "." is automatically added
						// when missing.
						matchName?: =~"^([-a-zA-Z0-9_]+[.]?)+$"

						// MatchPattern allows using wildcards to match DNS names. All wildcards are
						// case insensitive. The wildcards are:
						// - "*" matches 0 or more DNS valid characters, and may occur anywhere in
						// the pattern. As a special case a "*" as the leftmost character, without a
						// following "." matches all subdomains as well as the name to the right.
						// A trailing "." is automatically added when missing.
						// - "**." is a special prefix which matches all multilevel subdomains in the prefix.
						//
						// Examples:
						// 1. `*.cilium.io` matches subdomains of cilium at that level
						// www.cilium.io and blog.cilium.io match, cilium.io and google.com do not
						// 2. `*cilium.io` matches cilium.io and all subdomains ends with "cilium.io"
						// except those containing "." separator, subcilium.io and sub-cilium.io match,
						// www.cilium.io and blog.cilium.io does not
						// 3. `sub*.cilium.io` matches subdomains of cilium where the subdomain component
						// begins with "sub". sub.cilium.io and subdomain.cilium.io match while www.cilium.io,
						// blog.cilium.io, cilium.io and google.com do not
						// 4. `**.cilium.io` matches all multilevel subdomains of cilium.io.
						// "app.cilium.io" and "test.app.cilium.io" match but not "cilium.io"
						matchPattern?: =~"^([-a-zA-Z0-9_*]+[.]?)+$"
					}]

					// HTTP specific rules.
					http?: [...{
						// HeaderMatches is a list of HTTP headers which must be
						// present and match against the given values. Mismatch field can be used
						// to specify what to do when there is no match.
						headerMatches?: [...{
							// Mismatch identifies what to do in case there is no match. The default is
							// to drop the request. Otherwise the overall rule is still considered as
							// matching, but the mismatches are logged in the access log.
							mismatch?: "LOG" | "ADD" | "DELETE" | "REPLACE"

							// Name identifies the header.
							name!: string

							// Secret refers to a secret that contains the value to be matched against.
							// The secret must only contain one entry. If the referred secret does not
							// exist, and there is no "Value" specified, the match will fail.
							secret?: {
								// Name is the name of the secret.
								name!: string

								// Namespace is the namespace in which the secret exists. Context of use
								// determines the default value if left out (e.g., "default").
								namespace?: string
							}

							// Value matches the exact value of the header. Can be specified either
							// alone or together with "Secret"; will be used as the header value if the
							// secret can not be found in the latter case.
							value?: string
						}]

						// Headers is a list of HTTP headers which must be present in the
						// request. If omitted or empty, requests are allowed regardless of
						// headers present.
						headers?: [...string]

						// Host is an extended POSIX regex matched against the host header of a
						// request. Examples:
						//
						// - foo.bar.com will match the host fooXbar.com or foo-bar.com
						// - foo\.bar\.com will only match the host foo.bar.com
						//
						// If omitted or empty, the value of the host header is ignored.
						host?: string

						// Method is an extended POSIX regex matched against the method of a
						// request, e.g. "GET", "POST", "PUT", "PATCH", "DELETE", ...
						//
						// If omitted or empty, all methods are allowed.
						method?: string

						// Path is an extended POSIX regex matched against the path of a
						// request. Currently it can contain characters disallowed from the
						// conventional "path" part of a URL as defined by RFC 3986.
						//
						// If omitted or empty, all paths are all allowed.
						path?: string
					}]
				}

				// ServerNames is a list of allowed TLS SNI values. If not empty, then
				// TLS must be present and one of the provided SNIs must be indicated in the
				// TLS handshake.
				serverNames?: [...=~"^([-a-zA-Z0-9_*]+[.]?)+$"]

				// TerminatingTLS is the TLS context for the connection terminated by
				// the L7 proxy. For egress policy this specifies the server-side TLS
				// parameters to be applied on the connections originated from the local
				// endpoint and terminated by the L7 proxy. For ingress policy this specifies
				// the server-side TLS parameters to be applied on the connections
				// originated from a remote source and terminated by the L7 proxy.
				terminatingTLS?: {
					// Certificate is the file name or k8s secret item name for the certificate
					// chain. If omitted, 'tls.crt' is assumed, if it exists. If given, the
					// item must exist.
					certificate?: string

					// PrivateKey is the file name or k8s secret item name for the private key
					// matching the certificate chain. If omitted, 'tls.key' is assumed, if it
					// exists. If given, the item must exist.
					privateKey?: string

					// Secret is the secret that contains the certificates and private key for
					// the TLS context.
					// By default, Cilium will search in this secret for the following items:
					// - 'ca.crt' - Which represents the trusted CA to verify remote source.
					// - 'tls.crt' - Which represents the public key certificate.
					// - 'tls.key' - Which represents the private key matching the public key
					// certificate.
					secret!: {
						// Name is the name of the secret.
						name!: string

						// Namespace is the namespace in which the secret exists. Context of use
						// determines the default value if left out (e.g., "default").
						namespace?: string
					}

					// TrustedCA is the file name or k8s secret item name for the trusted CA.
					// If omitted, 'ca.crt' is assumed, if it exists. If given, the item must
					// exist.
					trustedCA?: string
				}
			}]

			// Deprecated.
			toRequires?: [...string]

			// ToServices is a list of services to which the endpoint subject
			// to the rule is allowed to initiate connections.
			// Currently Cilium only supports toServices for K8s services.
			toServices?: [...{
				// K8sService selects service by name and namespace pair
				k8sService?: {
					namespace?:   string
					serviceName?: string
				}

				// K8sServiceSelector selects services by k8s labels and namespace
				k8sServiceSelector?: {
					namespace?: string

					// ServiceSelector is a label selector for k8s services
					selector!: {
						// matchExpressions is a list of label selector requirements. The requirements are ANDed.
						matchExpressions?: [...{
							// key is the label key that the selector applies to.
							key!: string

							// operator represents a key's relationship to a set of values.
							// Valid operators are In, NotIn, Exists and DoesNotExist.
							operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

							// values is an array of string values. If the operator is In or NotIn,
							// the values array must be non-empty. If the operator is Exists or DoesNotExist,
							// the values array must be empty. This array is replaced during a strategic
							// merge patch.
							values?: [...string]
						}]

						// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
						// map is equivalent to an element of matchExpressions, whose key field is "key", the
						// operator is "In", and the values array contains only "value". The requirements are ANDed.
						matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
					}
				}
			}]
		}]

		// EgressDeny is a list of EgressDenyRule which are enforced at egress.
		// Any rule inserted here will be denied regardless of the allowed egress
		// rules in the 'egress' field.
		// If omitted or empty, this rule does not apply at egress.
		egressDeny?: [...{
			// ICMPs is a list of ICMP rule identified by type number
			// which the endpoint subject to the rule is not allowed to connect to.
			//
			// Example:
			// Any endpoint with the label "app=httpd" is not allowed to initiate
			// type 8 ICMP connections.
			icmps?: [...{
				// Fields is a list of ICMP fields.
				fields?: [...{
					// Family is a IP address version.
					// Currently, we support `IPv4` and `IPv6`.
					// `IPv4` is set as default.
					family?: "IPv4" | "IPv6"

					// Type is a ICMP-type.
					// It should be an 8bit code (0-255), or it's CamelCase name (for example, "EchoReply").
					// Allowed ICMP types are:
					// Ipv4: EchoReply | DestinationUnreachable | Redirect | Echo | EchoRequest |
					// RouterAdvertisement | RouterSelection | TimeExceeded | ParameterProblem |
					// Timestamp | TimestampReply | Photuris | ExtendedEcho Request | ExtendedEcho Reply
					// Ipv6: DestinationUnreachable | PacketTooBig | TimeExceeded | ParameterProblem |
					// EchoRequest | EchoReply | MulticastListenerQuery| MulticastListenerReport |
					// MulticastListenerDone | RouterSolicitation | RouterAdvertisement | NeighborSolicitation |
					// NeighborAdvertisement | RedirectMessage | RouterRenumbering | ICMPNodeInformationQuery |
					// ICMPNodeInformationResponse | InverseNeighborDiscoverySolicitation |
					// InverseNeighborDiscoveryAdvertisement |
					// HomeAgentAddressDiscoveryRequest | HomeAgentAddressDiscoveryReply | MobilePrefixSolicitation |
					// MobilePrefixAdvertisement | DuplicateAddressRequestCodeSuffix |
					// DuplicateAddressConfirmationCodeSuffix |
					// ExtendedEchoRequest | ExtendedEchoReply
					type!: (int |
						=~"^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]|EchoReply|DestinationUnreachable|Redirect|Echo|RouterAdvertisement|RouterSelection|TimeExceeded|ParameterProblem|Timestamp|TimestampReply|Photuris|ExtendedEchoRequest|ExtendedEcho Reply|PacketTooBig|ParameterProblem|EchoRequest|MulticastListenerQuery|MulticastListenerReport|MulticastListenerDone|RouterSolicitation|RouterAdvertisement|NeighborSolicitation|NeighborAdvertisement|RedirectMessage|RouterRenumbering|ICMPNodeInformationQuery|ICMPNodeInformationResponse|InverseNeighborDiscoverySolicitation|InverseNeighborDiscoveryAdvertisement|HomeAgentAddressDiscoveryRequest|HomeAgentAddressDiscoveryReply|MobilePrefixSolicitation|MobilePrefixAdvertisement|DuplicateAddressRequestCodeSuffix|DuplicateAddressConfirmationCodeSuffix)$")
				}]
			}]

			// ToCIDR is a list of IP blocks which the endpoint subject to the rule
			// is allowed to initiate connections. Only connections destined for
			// outside of the cluster and not targeting the host will be subject
			// to CIDR rules. This will match on the destination IP address of
			// outgoing connections. Adding a prefix into ToCIDR or into ToCIDRSet
			// with no ExcludeCIDRs is equivalent. Overlaps are allowed between
			// ToCIDR and ToCIDRSet.
			//
			// Example:
			// Any endpoint with the label "app=database-proxy" is allowed to
			// initiate connections to 10.2.3.0/24
			toCIDR?: [...string]

			// ToCIDRSet is a list of IP blocks which the endpoint subject to the rule
			// is allowed to initiate connections to in addition to connections
			// which are allowed via ToEndpoints, along with a list of subnets contained
			// within their corresponding IP block to which traffic should not be
			// allowed. This will match on the destination IP address of outgoing
			// connections. Adding a prefix into ToCIDR or into ToCIDRSet with no
			// ExcludeCIDRs is equivalent. Overlaps are allowed between ToCIDR and
			// ToCIDRSet.
			//
			// Example:
			// Any endpoint with the label "app=database-proxy" is allowed to
			// initiate connections to 10.2.3.0/24 except from IPs in subnet 10.2.3.0/28.
			toCIDRSet?: [...{
				// CIDR is a CIDR prefix / IP Block.
				cidr?: string

				// CIDRGroupRef is a reference to a CiliumCIDRGroup object.
				// A CiliumCIDRGroup contains a list of CIDRs that the endpoint, subject to
				// the rule, can (Ingress/Egress) or cannot (IngressDeny/EgressDeny) receive
				// connections from.
				cidrGroupRef?: =~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"

				// CIDRGroupSelector selects CiliumCIDRGroups by their labels,
				// rather than by name.
				cidrGroupSelector?: {
					// matchExpressions is a list of label selector requirements. The requirements are ANDed.
					matchExpressions?: [...{
						// key is the label key that the selector applies to.
						key!: string

						// operator represents a key's relationship to a set of values.
						// Valid operators are In, NotIn, Exists and DoesNotExist.
						operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

						// values is an array of string values. If the operator is In or NotIn,
						// the values array must be non-empty. If the operator is Exists or DoesNotExist,
						// the values array must be empty. This array is replaced during a strategic
						// merge patch.
						values?: [...string]
					}]

					// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
					// map is equivalent to an element of matchExpressions, whose key field is "key", the
					// operator is "In", and the values array contains only "value". The requirements are ANDed.
					matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
				}

				// ExceptCIDRs is a list of IP blocks which the endpoint subject to the rule
				// is not allowed to initiate connections to. These CIDR prefixes should be
				// contained within Cidr, using ExceptCIDRs together with CIDRGroupRef is not
				// supported yet.
				// These exceptions are only applied to the Cidr in this CIDRRule, and do not
				// apply to any other CIDR prefixes in any other CIDRRules.
				except?: [...string]
			}]

			// ToEndpoints is a list of endpoints identified by an EndpointSelector to
			// which the endpoints subject to the rule are allowed to communicate.
			//
			// Example:
			// Any endpoint with the label "role=frontend" can communicate with any
			// endpoint carrying the label "role=backend".
			//
			// Note that while an empty non-nil ToEndpoints does not select anything,
			// nil ToEndpoints is implicitly treated as a wildcard selector if ToPorts
			// are also specified.
			// To select everything, use one EndpointSelector without any match requirements.
			toEndpoints?: [...{
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
			}]

			// ToEntities is a list of special entities to which the endpoint subject
			// to the rule is allowed to initiate connections. Supported entities are
			// `world`, `cluster`, `cluster-mesh`, `host`, `remote-node`, `kube-apiserver`, `ingress`, `init`,
			// `health`, `unmanaged`, `none` and `all`.
			toEntities?: [
				..."all" |
					"world" |
					"cluster" |
					"cluster-mesh" |
					"host" |
					"init" |
					"ingress" |
					"unmanaged" |
					"remote-node" |
					"health" |
					"none" |
					"kube-apiserver",
			]

			// ToGroups allows policies to reference CIDRs provided by external integrations.
			// Currently, only AWS is supported, and the rule can select by multiple sub directives.
			// ToGroups entries are functionally equivalent to toCIDR, and have the same
			// limitiations. They cannot select traffic originating from within the cluster.
			//
			// Example:
			// toGroups:
			// - aws:
			// securityGroupsIds:
			// - 'sg-XXXXXXXXXXXXX'
			toGroups?: [...{
				// AWSGroup is an structure that can be used to whitelisting information from AWS integration
				aws?: {
					// Labels selects AWS ENIs by labels.
					// Multiple labels are AND-ed together.
					labels?: [string]: string

					// Deprecated: Region is unused.
					region?: string

					// SecurityGroupsIds selects VPC SecurityGroups by IDs.
					// If multiple IDs are specified, they are OR-ed together.
					//
					// Note that this may be AND-ed with any Names specified. Specifying both
					// IDs and Names is not recommended.
					securityGroupsIds?: [...string]

					// SecurityGroupsNames selects VPC SecurityGroups by name.
					// If multiple names are specified, they are OR-ed together.
					//
					// Note that this may be AND-ed with any IDs specified. Specifying both
					// IDs and Names is not recommended.
					securityGroupsNames?: [...string]
				}
			}]

			// ToNodes is a list of nodes identified by an
			// EndpointSelector to which endpoints subject to the rule is allowed to communicate.
			toNodes?: [...{
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
			}]

			// ToPorts is a list of destination ports identified by port number and
			// protocol which the endpoint subject to the rule is not allowed to connect
			// to.
			//
			// Example:
			// Any endpoint with the label "role=frontend" is not allowed to initiate
			// connections to destination port 8080/tcp
			toPorts?: [...{
				// Ports is a list of L4 port/protocol
				ports?: [...{
					// EndPort can only be an L4 port number.
					endPort?: int32 & int & <=65535 & >=0

					// Port can be an L4 port number, or a name in the form of "http"
					// or "http-8080".
					port?:
						=~"^(6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[0-9]{1,4})|([a-zA-Z0-9]-?)*[a-zA-Z](-?[a-zA-Z0-9])*$"

					// Protocol is the L4 protocol. If "ANY", omitted or empty, any protocols
					// with transport ports (TCP, UDP, SCTP) match.
					//
					// Accepted values: "TCP", "UDP", "SCTP", "VRRP", "IGMP", "GRE", "IPIP",
					// "IPV6", "ESP", "AH", "ANY"
					//
					// Tunnel/encapsulation protocols (GRE, IPIP, IPV6, ESP, AH) and other
					// extended IP protocols (VRRP, IGMP) require the --enable-extended-ip-protocols
					// flag to be set. These protocols do not use transport-layer ports.
					//
					// Matching on ICMP is not supported.
					//
					// Named port specified for a container may narrow this down, but may not
					// contradict this.
					protocol?: "TCP" | "UDP" | "SCTP" | "VRRP" | "IGMP" | "GRE" | "IPIP" | "IPV6" | "ESP" | "AH" | "ANY"
				}]
			}]

			// Deprecated.
			toRequires?: [...string]

			// ToServices is a list of services to which the endpoint subject
			// to the rule is allowed to initiate connections.
			// Currently Cilium only supports toServices for K8s services.
			toServices?: [...{
				// K8sService selects service by name and namespace pair
				k8sService?: {
					namespace?:   string
					serviceName?: string
				}

				// K8sServiceSelector selects services by k8s labels and namespace
				k8sServiceSelector?: {
					namespace?: string

					// ServiceSelector is a label selector for k8s services
					selector!: {
						// matchExpressions is a list of label selector requirements. The requirements are ANDed.
						matchExpressions?: [...{
							// key is the label key that the selector applies to.
							key!: string

							// operator represents a key's relationship to a set of values.
							// Valid operators are In, NotIn, Exists and DoesNotExist.
							operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

							// values is an array of string values. If the operator is In or NotIn,
							// the values array must be non-empty. If the operator is Exists or DoesNotExist,
							// the values array must be empty. This array is replaced during a strategic
							// merge patch.
							values?: [...string]
						}]

						// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
						// map is equivalent to an element of matchExpressions, whose key field is "key", the
						// operator is "In", and the values array contains only "value". The requirements are ANDed.
						matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
					}
				}
			}]
		}]

		// EnableDefaultDeny determines whether this policy configures the
		// subject endpoint(s) to have a default deny mode. If enabled,
		// this causes all traffic not explicitly allowed by a network policy
		// to be dropped.
		//
		// If not specified, the default is true for each traffic direction
		// that has rules, and false otherwise. For example, if a policy
		// only has Ingress or IngressDeny rules, then the default for
		// ingress is true and egress is false.
		//
		// If multiple policies apply to an endpoint, that endpoint's default deny
		// will be enabled if any policy requests it.
		//
		// This is useful for creating broad-based network policies that will not
		// cause endpoints to enter default-deny mode.
		enableDefaultDeny?: {
			// Whether or not the endpoint should have a default-deny rule applied
			// to egress traffic.
			egress?: bool

			// Whether or not the endpoint should have a default-deny rule applied
			// to ingress traffic.
			ingress?: bool
		}

		// EndpointSelector selects all endpoints which should be subject to
		// this rule. EndpointSelector and NodeSelector cannot be both empty and
		// are mutually exclusive.
		endpointSelector?: {
			// matchExpressions is a list of label selector requirements. The requirements are ANDed.
			matchExpressions?: [...{
				// key is the label key that the selector applies to.
				key!: string

				// operator represents a key's relationship to a set of values.
				// Valid operators are In, NotIn, Exists and DoesNotExist.
				operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

				// values is an array of string values. If the operator is In or NotIn,
				// the values array must be non-empty. If the operator is Exists or DoesNotExist,
				// the values array must be empty. This array is replaced during a strategic
				// merge patch.
				values?: [...string]
			}]

			// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
			// map is equivalent to an element of matchExpressions, whose key field is "key", the
			// operator is "In", and the values array contains only "value". The requirements are ANDed.
			matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
		}

		// Ingress is a list of IngressRule which are enforced at ingress.
		// If omitted or empty, this rule does not apply at ingress.
		ingress?: [...{
			// Authentication is the required authentication type for the allowed traffic, if any.
			authentication?: {
				// Mode is the required authentication mode for the allowed traffic, if any.
				mode!: "disabled" | "required" | "test-always-fail"
			}

			// FromCIDR is a list of IP blocks which the endpoint subject to the
			// rule is allowed to receive connections from. Only connections which
			// do *not* originate from the cluster or from the local host are subject
			// to CIDR rules. In order to allow in-cluster connectivity, use the
			// FromEndpoints field. This will match on the source IP address of
			// incoming connections. Adding a prefix into FromCIDR or into
			// FromCIDRSet with no ExcludeCIDRs is equivalent. Overlaps are
			// allowed between FromCIDR and FromCIDRSet.
			//
			// Example:
			// Any endpoint with the label "app=my-legacy-pet" is allowed to receive
			// connections from 10.3.9.1
			fromCIDR?: [...string]

			// FromCIDRSet is a list of IP blocks which the endpoint subject to the
			// rule is allowed to receive connections from in addition to FromEndpoints,
			// along with a list of subnets contained within their corresponding IP block
			// from which traffic should not be allowed.
			// This will match on the source IP address of incoming connections. Adding
			// a prefix into FromCIDR or into FromCIDRSet with no ExcludeCIDRs is
			// equivalent. Overlaps are allowed between FromCIDR and FromCIDRSet.
			//
			// Example:
			// Any endpoint with the label "app=my-legacy-pet" is allowed to receive
			// connections from 10.0.0.0/8 except from IPs in subnet 10.96.0.0/12.
			fromCIDRSet?: [...{
				// CIDR is a CIDR prefix / IP Block.
				cidr?: string

				// CIDRGroupRef is a reference to a CiliumCIDRGroup object.
				// A CiliumCIDRGroup contains a list of CIDRs that the endpoint, subject to
				// the rule, can (Ingress/Egress) or cannot (IngressDeny/EgressDeny) receive
				// connections from.
				cidrGroupRef?: =~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"

				// CIDRGroupSelector selects CiliumCIDRGroups by their labels,
				// rather than by name.
				cidrGroupSelector?: {
					// matchExpressions is a list of label selector requirements. The requirements are ANDed.
					matchExpressions?: [...{
						// key is the label key that the selector applies to.
						key!: string

						// operator represents a key's relationship to a set of values.
						// Valid operators are In, NotIn, Exists and DoesNotExist.
						operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

						// values is an array of string values. If the operator is In or NotIn,
						// the values array must be non-empty. If the operator is Exists or DoesNotExist,
						// the values array must be empty. This array is replaced during a strategic
						// merge patch.
						values?: [...string]
					}]

					// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
					// map is equivalent to an element of matchExpressions, whose key field is "key", the
					// operator is "In", and the values array contains only "value". The requirements are ANDed.
					matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
				}

				// ExceptCIDRs is a list of IP blocks which the endpoint subject to the rule
				// is not allowed to initiate connections to. These CIDR prefixes should be
				// contained within Cidr, using ExceptCIDRs together with CIDRGroupRef is not
				// supported yet.
				// These exceptions are only applied to the Cidr in this CIDRRule, and do not
				// apply to any other CIDR prefixes in any other CIDRRules.
				except?: [...string]
			}]

			// FromEndpoints is a list of endpoints identified by an
			// EndpointSelector which are allowed to communicate with the endpoint
			// subject to the rule.
			//
			// Example:
			// Any endpoint with the label "role=backend" can be consumed by any
			// endpoint carrying the label "role=frontend".
			//
			// Note that while an empty non-nil FromEndpoints does not select anything,
			// nil FromEndpoints is implicitly treated as a wildcard selector if ToPorts
			// are also specified.
			// To select everything, use one EndpointSelector without any match requirements.
			fromEndpoints?: [...{
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
			}]

			// FromEntities is a list of special entities which the endpoint subject
			// to the rule is allowed to receive connections from. Supported entities are
			// `world`, `cluster`, `cluster-mesh`, `host`, `remote-node`, `kube-apiserver`, `ingress`, `init`,
			// `health`, `unmanaged`, `none` and `all`.
			fromEntities?: [
				..."all" |
					"world" |
					"cluster" |
					"cluster-mesh" |
					"host" |
					"init" |
					"ingress" |
					"unmanaged" |
					"remote-node" |
					"health" |
					"none" |
					"kube-apiserver",
			]

			// FromGroups allows policies to reference CIDRs provided by external integrations.
			// Currently, only AWS is supported, and the rule can select by multiple sub directives.
			// FromGroups entries are functionally equivalent to FromCIDR, and have the same
			// limitiations. They cannot select traffic originating from within the cluster.
			//
			// Example:
			// fromGroups:
			// - aws:
			// securityGroupsIds:
			// - 'sg-XXXXXXXXXXXXX'
			fromGroups?: [...{
				// AWSGroup is an structure that can be used to whitelisting information from AWS integration
				aws?: {
					// Labels selects AWS ENIs by labels.
					// Multiple labels are AND-ed together.
					labels?: [string]: string

					// Deprecated: Region is unused.
					region?: string

					// SecurityGroupsIds selects VPC SecurityGroups by IDs.
					// If multiple IDs are specified, they are OR-ed together.
					//
					// Note that this may be AND-ed with any Names specified. Specifying both
					// IDs and Names is not recommended.
					securityGroupsIds?: [...string]

					// SecurityGroupsNames selects VPC SecurityGroups by name.
					// If multiple names are specified, they are OR-ed together.
					//
					// Note that this may be AND-ed with any IDs specified. Specifying both
					// IDs and Names is not recommended.
					securityGroupsNames?: [...string]
				}
			}]

			// FromNodes is a list of nodes identified by an
			// EndpointSelector which are allowed to communicate with the endpoint
			// subject to the rule.
			fromNodes?: [...{
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
			}]

			// Deprecated.
			fromRequires?: [...string]

			// ICMPs is a list of ICMP rule identified by type number
			// which the endpoint subject to the rule is allowed to
			// receive connections on.
			//
			// Example:
			// Any endpoint with the label "app=httpd" can only accept incoming
			// type 8 ICMP connections.
			icmps?: [...{
				// Fields is a list of ICMP fields.
				fields?: [...{
					// Family is a IP address version.
					// Currently, we support `IPv4` and `IPv6`.
					// `IPv4` is set as default.
					family?: "IPv4" | "IPv6"

					// Type is a ICMP-type.
					// It should be an 8bit code (0-255), or it's CamelCase name (for example, "EchoReply").
					// Allowed ICMP types are:
					// Ipv4: EchoReply | DestinationUnreachable | Redirect | Echo | EchoRequest |
					// RouterAdvertisement | RouterSelection | TimeExceeded | ParameterProblem |
					// Timestamp | TimestampReply | Photuris | ExtendedEcho Request | ExtendedEcho Reply
					// Ipv6: DestinationUnreachable | PacketTooBig | TimeExceeded | ParameterProblem |
					// EchoRequest | EchoReply | MulticastListenerQuery| MulticastListenerReport |
					// MulticastListenerDone | RouterSolicitation | RouterAdvertisement | NeighborSolicitation |
					// NeighborAdvertisement | RedirectMessage | RouterRenumbering | ICMPNodeInformationQuery |
					// ICMPNodeInformationResponse | InverseNeighborDiscoverySolicitation |
					// InverseNeighborDiscoveryAdvertisement |
					// HomeAgentAddressDiscoveryRequest | HomeAgentAddressDiscoveryReply | MobilePrefixSolicitation |
					// MobilePrefixAdvertisement | DuplicateAddressRequestCodeSuffix |
					// DuplicateAddressConfirmationCodeSuffix |
					// ExtendedEchoRequest | ExtendedEchoReply
					type!: (int |
						=~"^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]|EchoReply|DestinationUnreachable|Redirect|Echo|RouterAdvertisement|RouterSelection|TimeExceeded|ParameterProblem|Timestamp|TimestampReply|Photuris|ExtendedEchoRequest|ExtendedEcho Reply|PacketTooBig|ParameterProblem|EchoRequest|MulticastListenerQuery|MulticastListenerReport|MulticastListenerDone|RouterSolicitation|RouterAdvertisement|NeighborSolicitation|NeighborAdvertisement|RedirectMessage|RouterRenumbering|ICMPNodeInformationQuery|ICMPNodeInformationResponse|InverseNeighborDiscoverySolicitation|InverseNeighborDiscoveryAdvertisement|HomeAgentAddressDiscoveryRequest|HomeAgentAddressDiscoveryReply|MobilePrefixSolicitation|MobilePrefixAdvertisement|DuplicateAddressRequestCodeSuffix|DuplicateAddressConfirmationCodeSuffix)$")
				}]
			}]

			// ToPorts is a list of destination ports identified by port number and
			// protocol which the endpoint subject to the rule is allowed to
			// receive connections on.
			//
			// Example:
			// Any endpoint with the label "app=httpd" can only accept incoming
			// connections on port 80/tcp.
			toPorts?: [...{
				// listener specifies the name of a custom Envoy listener to which this traffic should be
				// redirected to.
				listener?: {
					// EnvoyConfig is a reference to the CEC or CCEC resource in which
					// the listener is defined.
					envoyConfig!: {
						// Kind is the resource type being referred to. Defaults to CiliumEnvoyConfig or
						// CiliumClusterwideEnvoyConfig for CiliumNetworkPolicy and CiliumClusterwideNetworkPolicy,
						// respectively. The only case this is currently explicitly needed is when referring to a
						// CiliumClusterwideEnvoyConfig from CiliumNetworkPolicy, as using a namespaced listener
						// from a cluster scoped policy is not allowed.
						kind?: "CiliumEnvoyConfig" | "CiliumClusterwideEnvoyConfig"

						// Name is the resource name of the CiliumEnvoyConfig or CiliumClusterwideEnvoyConfig where
						// the listener is defined in.
						name!: string
					}

					// Name is the name of the listener.
					name!: string

					// Priority for this Listener that is used when multiple rules would apply different
					// listeners to a policy map entry. Behavior of this is implementation dependent.
					priority?: int & <=100 & >=1
				}

				// OriginatingTLS is the TLS context for the connections originated by
				// the L7 proxy. For egress policy this specifies the client-side TLS
				// parameters for the upstream connection originating from the L7 proxy
				// to the remote destination. For ingress policy this specifies the
				// client-side TLS parameters for the connection from the L7 proxy to
				// the local endpoint.
				originatingTLS?: {
					// Certificate is the file name or k8s secret item name for the certificate
					// chain. If omitted, 'tls.crt' is assumed, if it exists. If given, the
					// item must exist.
					certificate?: string

					// PrivateKey is the file name or k8s secret item name for the private key
					// matching the certificate chain. If omitted, 'tls.key' is assumed, if it
					// exists. If given, the item must exist.
					privateKey?: string

					// Secret is the secret that contains the certificates and private key for
					// the TLS context.
					// By default, Cilium will search in this secret for the following items:
					// - 'ca.crt' - Which represents the trusted CA to verify remote source.
					// - 'tls.crt' - Which represents the public key certificate.
					// - 'tls.key' - Which represents the private key matching the public key
					// certificate.
					secret!: {
						// Name is the name of the secret.
						name!: string

						// Namespace is the namespace in which the secret exists. Context of use
						// determines the default value if left out (e.g., "default").
						namespace?: string
					}

					// TrustedCA is the file name or k8s secret item name for the trusted CA.
					// If omitted, 'ca.crt' is assumed, if it exists. If given, the item must
					// exist.
					trustedCA?: string
				}

				// Ports is a list of L4 port/protocol
				ports?: [...{
					// EndPort can only be an L4 port number.
					endPort?: int32 & int & <=65535 & >=0

					// Port can be an L4 port number, or a name in the form of "http"
					// or "http-8080".
					port?:
						=~"^(6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[0-9]{1,4})|([a-zA-Z0-9]-?)*[a-zA-Z](-?[a-zA-Z0-9])*$"

					// Protocol is the L4 protocol. If "ANY", omitted or empty, any protocols
					// with transport ports (TCP, UDP, SCTP) match.
					//
					// Accepted values: "TCP", "UDP", "SCTP", "VRRP", "IGMP", "GRE", "IPIP",
					// "IPV6", "ESP", "AH", "ANY"
					//
					// Tunnel/encapsulation protocols (GRE, IPIP, IPV6, ESP, AH) and other
					// extended IP protocols (VRRP, IGMP) require the --enable-extended-ip-protocols
					// flag to be set. These protocols do not use transport-layer ports.
					//
					// Matching on ICMP is not supported.
					//
					// Named port specified for a container may narrow this down, but may not
					// contradict this.
					protocol?: "TCP" | "UDP" | "SCTP" | "VRRP" | "IGMP" | "GRE" | "IPIP" | "IPV6" | "ESP" | "AH" | "ANY"
				}]

				// Rules is a list of additional port level rules which must be met in
				// order for the PortRule to allow the traffic. If omitted or empty,
				// no layer 7 rules are enforced.
				rules?: {
					// DNS-specific rules.
					dns?: [...{
						// MatchName matches literal DNS names. A trailing "." is automatically added
						// when missing.
						matchName?: =~"^([-a-zA-Z0-9_]+[.]?)+$"

						// MatchPattern allows using wildcards to match DNS names. All wildcards are
						// case insensitive. The wildcards are:
						// - "*" matches 0 or more DNS valid characters, and may occur anywhere in
						// the pattern. As a special case a "*" as the leftmost character, without a
						// following "." matches all subdomains as well as the name to the right.
						// A trailing "." is automatically added when missing.
						// - "**." is a special prefix which matches all multilevel subdomains in the prefix.
						//
						// Examples:
						// 1. `*.cilium.io` matches subdomains of cilium at that level
						// www.cilium.io and blog.cilium.io match, cilium.io and google.com do not
						// 2. `*cilium.io` matches cilium.io and all subdomains ends with "cilium.io"
						// except those containing "." separator, subcilium.io and sub-cilium.io match,
						// www.cilium.io and blog.cilium.io does not
						// 3. `sub*.cilium.io` matches subdomains of cilium where the subdomain component
						// begins with "sub". sub.cilium.io and subdomain.cilium.io match while www.cilium.io,
						// blog.cilium.io, cilium.io and google.com do not
						// 4. `**.cilium.io` matches all multilevel subdomains of cilium.io.
						// "app.cilium.io" and "test.app.cilium.io" match but not "cilium.io"
						matchPattern?: =~"^([-a-zA-Z0-9_*]+[.]?)+$"
					}]

					// HTTP specific rules.
					http?: [...{
						// HeaderMatches is a list of HTTP headers which must be
						// present and match against the given values. Mismatch field can be used
						// to specify what to do when there is no match.
						headerMatches?: [...{
							// Mismatch identifies what to do in case there is no match. The default is
							// to drop the request. Otherwise the overall rule is still considered as
							// matching, but the mismatches are logged in the access log.
							mismatch?: "LOG" | "ADD" | "DELETE" | "REPLACE"

							// Name identifies the header.
							name!: string

							// Secret refers to a secret that contains the value to be matched against.
							// The secret must only contain one entry. If the referred secret does not
							// exist, and there is no "Value" specified, the match will fail.
							secret?: {
								// Name is the name of the secret.
								name!: string

								// Namespace is the namespace in which the secret exists. Context of use
								// determines the default value if left out (e.g., "default").
								namespace?: string
							}

							// Value matches the exact value of the header. Can be specified either
							// alone or together with "Secret"; will be used as the header value if the
							// secret can not be found in the latter case.
							value?: string
						}]

						// Headers is a list of HTTP headers which must be present in the
						// request. If omitted or empty, requests are allowed regardless of
						// headers present.
						headers?: [...string]

						// Host is an extended POSIX regex matched against the host header of a
						// request. Examples:
						//
						// - foo.bar.com will match the host fooXbar.com or foo-bar.com
						// - foo\.bar\.com will only match the host foo.bar.com
						//
						// If omitted or empty, the value of the host header is ignored.
						host?: string

						// Method is an extended POSIX regex matched against the method of a
						// request, e.g. "GET", "POST", "PUT", "PATCH", "DELETE", ...
						//
						// If omitted or empty, all methods are allowed.
						method?: string

						// Path is an extended POSIX regex matched against the path of a
						// request. Currently it can contain characters disallowed from the
						// conventional "path" part of a URL as defined by RFC 3986.
						//
						// If omitted or empty, all paths are all allowed.
						path?: string
					}]
				}

				// ServerNames is a list of allowed TLS SNI values. If not empty, then
				// TLS must be present and one of the provided SNIs must be indicated in the
				// TLS handshake.
				serverNames?: [...=~"^([-a-zA-Z0-9_*]+[.]?)+$"]

				// TerminatingTLS is the TLS context for the connection terminated by
				// the L7 proxy. For egress policy this specifies the server-side TLS
				// parameters to be applied on the connections originated from the local
				// endpoint and terminated by the L7 proxy. For ingress policy this specifies
				// the server-side TLS parameters to be applied on the connections
				// originated from a remote source and terminated by the L7 proxy.
				terminatingTLS?: {
					// Certificate is the file name or k8s secret item name for the certificate
					// chain. If omitted, 'tls.crt' is assumed, if it exists. If given, the
					// item must exist.
					certificate?: string

					// PrivateKey is the file name or k8s secret item name for the private key
					// matching the certificate chain. If omitted, 'tls.key' is assumed, if it
					// exists. If given, the item must exist.
					privateKey?: string

					// Secret is the secret that contains the certificates and private key for
					// the TLS context.
					// By default, Cilium will search in this secret for the following items:
					// - 'ca.crt' - Which represents the trusted CA to verify remote source.
					// - 'tls.crt' - Which represents the public key certificate.
					// - 'tls.key' - Which represents the private key matching the public key
					// certificate.
					secret!: {
						// Name is the name of the secret.
						name!: string

						// Namespace is the namespace in which the secret exists. Context of use
						// determines the default value if left out (e.g., "default").
						namespace?: string
					}

					// TrustedCA is the file name or k8s secret item name for the trusted CA.
					// If omitted, 'ca.crt' is assumed, if it exists. If given, the item must
					// exist.
					trustedCA?: string
				}
			}]
		}]

		// IngressDeny is a list of IngressDenyRule which are enforced at ingress.
		// Any rule inserted here will be denied regardless of the allowed ingress
		// rules in the 'ingress' field.
		// If omitted or empty, this rule does not apply at ingress.
		ingressDeny?: [...{
			// FromCIDR is a list of IP blocks which the endpoint subject to the
			// rule is allowed to receive connections from. Only connections which
			// do *not* originate from the cluster or from the local host are subject
			// to CIDR rules. In order to allow in-cluster connectivity, use the
			// FromEndpoints field. This will match on the source IP address of
			// incoming connections. Adding a prefix into FromCIDR or into
			// FromCIDRSet with no ExcludeCIDRs is equivalent. Overlaps are
			// allowed between FromCIDR and FromCIDRSet.
			//
			// Example:
			// Any endpoint with the label "app=my-legacy-pet" is allowed to receive
			// connections from 10.3.9.1
			fromCIDR?: [...string]

			// FromCIDRSet is a list of IP blocks which the endpoint subject to the
			// rule is allowed to receive connections from in addition to FromEndpoints,
			// along with a list of subnets contained within their corresponding IP block
			// from which traffic should not be allowed.
			// This will match on the source IP address of incoming connections. Adding
			// a prefix into FromCIDR or into FromCIDRSet with no ExcludeCIDRs is
			// equivalent. Overlaps are allowed between FromCIDR and FromCIDRSet.
			//
			// Example:
			// Any endpoint with the label "app=my-legacy-pet" is allowed to receive
			// connections from 10.0.0.0/8 except from IPs in subnet 10.96.0.0/12.
			fromCIDRSet?: [...{
				// CIDR is a CIDR prefix / IP Block.
				cidr?: string

				// CIDRGroupRef is a reference to a CiliumCIDRGroup object.
				// A CiliumCIDRGroup contains a list of CIDRs that the endpoint, subject to
				// the rule, can (Ingress/Egress) or cannot (IngressDeny/EgressDeny) receive
				// connections from.
				cidrGroupRef?: =~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"

				// CIDRGroupSelector selects CiliumCIDRGroups by their labels,
				// rather than by name.
				cidrGroupSelector?: {
					// matchExpressions is a list of label selector requirements. The requirements are ANDed.
					matchExpressions?: [...{
						// key is the label key that the selector applies to.
						key!: string

						// operator represents a key's relationship to a set of values.
						// Valid operators are In, NotIn, Exists and DoesNotExist.
						operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

						// values is an array of string values. If the operator is In or NotIn,
						// the values array must be non-empty. If the operator is Exists or DoesNotExist,
						// the values array must be empty. This array is replaced during a strategic
						// merge patch.
						values?: [...string]
					}]

					// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
					// map is equivalent to an element of matchExpressions, whose key field is "key", the
					// operator is "In", and the values array contains only "value". The requirements are ANDed.
					matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
				}

				// ExceptCIDRs is a list of IP blocks which the endpoint subject to the rule
				// is not allowed to initiate connections to. These CIDR prefixes should be
				// contained within Cidr, using ExceptCIDRs together with CIDRGroupRef is not
				// supported yet.
				// These exceptions are only applied to the Cidr in this CIDRRule, and do not
				// apply to any other CIDR prefixes in any other CIDRRules.
				except?: [...string]
			}]

			// FromEndpoints is a list of endpoints identified by an
			// EndpointSelector which are allowed to communicate with the endpoint
			// subject to the rule.
			//
			// Example:
			// Any endpoint with the label "role=backend" can be consumed by any
			// endpoint carrying the label "role=frontend".
			//
			// Note that while an empty non-nil FromEndpoints does not select anything,
			// nil FromEndpoints is implicitly treated as a wildcard selector if ToPorts
			// are also specified.
			// To select everything, use one EndpointSelector without any match requirements.
			fromEndpoints?: [...{
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
			}]

			// FromEntities is a list of special entities which the endpoint subject
			// to the rule is allowed to receive connections from. Supported entities are
			// `world`, `cluster`, `cluster-mesh`, `host`, `remote-node`, `kube-apiserver`, `ingress`, `init`,
			// `health`, `unmanaged`, `none` and `all`.
			fromEntities?: [
				..."all" |
					"world" |
					"cluster" |
					"cluster-mesh" |
					"host" |
					"init" |
					"ingress" |
					"unmanaged" |
					"remote-node" |
					"health" |
					"none" |
					"kube-apiserver",
			]

			// FromGroups allows policies to reference CIDRs provided by external integrations.
			// Currently, only AWS is supported, and the rule can select by multiple sub directives.
			// FromGroups entries are functionally equivalent to FromCIDR, and have the same
			// limitiations. They cannot select traffic originating from within the cluster.
			//
			// Example:
			// fromGroups:
			// - aws:
			// securityGroupsIds:
			// - 'sg-XXXXXXXXXXXXX'
			fromGroups?: [...{
				// AWSGroup is an structure that can be used to whitelisting information from AWS integration
				aws?: {
					// Labels selects AWS ENIs by labels.
					// Multiple labels are AND-ed together.
					labels?: [string]: string

					// Deprecated: Region is unused.
					region?: string

					// SecurityGroupsIds selects VPC SecurityGroups by IDs.
					// If multiple IDs are specified, they are OR-ed together.
					//
					// Note that this may be AND-ed with any Names specified. Specifying both
					// IDs and Names is not recommended.
					securityGroupsIds?: [...string]

					// SecurityGroupsNames selects VPC SecurityGroups by name.
					// If multiple names are specified, they are OR-ed together.
					//
					// Note that this may be AND-ed with any IDs specified. Specifying both
					// IDs and Names is not recommended.
					securityGroupsNames?: [...string]
				}
			}]

			// FromNodes is a list of nodes identified by an
			// EndpointSelector which are allowed to communicate with the endpoint
			// subject to the rule.
			fromNodes?: [...{
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
			}]

			// Deprecated.
			fromRequires?: [...string]

			// ICMPs is a list of ICMP rule identified by type number
			// which the endpoint subject to the rule is not allowed to
			// receive connections on.
			//
			// Example:
			// Any endpoint with the label "app=httpd" can not accept incoming
			// type 8 ICMP connections.
			icmps?: [...{
				// Fields is a list of ICMP fields.
				fields?: [...{
					// Family is a IP address version.
					// Currently, we support `IPv4` and `IPv6`.
					// `IPv4` is set as default.
					family?: "IPv4" | "IPv6"

					// Type is a ICMP-type.
					// It should be an 8bit code (0-255), or it's CamelCase name (for example, "EchoReply").
					// Allowed ICMP types are:
					// Ipv4: EchoReply | DestinationUnreachable | Redirect | Echo | EchoRequest |
					// RouterAdvertisement | RouterSelection | TimeExceeded | ParameterProblem |
					// Timestamp | TimestampReply | Photuris | ExtendedEcho Request | ExtendedEcho Reply
					// Ipv6: DestinationUnreachable | PacketTooBig | TimeExceeded | ParameterProblem |
					// EchoRequest | EchoReply | MulticastListenerQuery| MulticastListenerReport |
					// MulticastListenerDone | RouterSolicitation | RouterAdvertisement | NeighborSolicitation |
					// NeighborAdvertisement | RedirectMessage | RouterRenumbering | ICMPNodeInformationQuery |
					// ICMPNodeInformationResponse | InverseNeighborDiscoverySolicitation |
					// InverseNeighborDiscoveryAdvertisement |
					// HomeAgentAddressDiscoveryRequest | HomeAgentAddressDiscoveryReply | MobilePrefixSolicitation |
					// MobilePrefixAdvertisement | DuplicateAddressRequestCodeSuffix |
					// DuplicateAddressConfirmationCodeSuffix |
					// ExtendedEchoRequest | ExtendedEchoReply
					type!: (int |
						=~"^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]|EchoReply|DestinationUnreachable|Redirect|Echo|RouterAdvertisement|RouterSelection|TimeExceeded|ParameterProblem|Timestamp|TimestampReply|Photuris|ExtendedEchoRequest|ExtendedEcho Reply|PacketTooBig|ParameterProblem|EchoRequest|MulticastListenerQuery|MulticastListenerReport|MulticastListenerDone|RouterSolicitation|RouterAdvertisement|NeighborSolicitation|NeighborAdvertisement|RedirectMessage|RouterRenumbering|ICMPNodeInformationQuery|ICMPNodeInformationResponse|InverseNeighborDiscoverySolicitation|InverseNeighborDiscoveryAdvertisement|HomeAgentAddressDiscoveryRequest|HomeAgentAddressDiscoveryReply|MobilePrefixSolicitation|MobilePrefixAdvertisement|DuplicateAddressRequestCodeSuffix|DuplicateAddressConfirmationCodeSuffix)$")
				}]
			}]

			// ToPorts is a list of destination ports identified by port number and
			// protocol which the endpoint subject to the rule is not allowed to
			// receive connections on.
			//
			// Example:
			// Any endpoint with the label "app=httpd" can not accept incoming
			// connections on port 80/tcp.
			toPorts?: [...{
				// Ports is a list of L4 port/protocol
				ports?: [...{
					// EndPort can only be an L4 port number.
					endPort?: int32 & int & <=65535 & >=0

					// Port can be an L4 port number, or a name in the form of "http"
					// or "http-8080".
					port?:
						=~"^(6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[0-9]{1,4})|([a-zA-Z0-9]-?)*[a-zA-Z](-?[a-zA-Z0-9])*$"

					// Protocol is the L4 protocol. If "ANY", omitted or empty, any protocols
					// with transport ports (TCP, UDP, SCTP) match.
					//
					// Accepted values: "TCP", "UDP", "SCTP", "VRRP", "IGMP", "GRE", "IPIP",
					// "IPV6", "ESP", "AH", "ANY"
					//
					// Tunnel/encapsulation protocols (GRE, IPIP, IPV6, ESP, AH) and other
					// extended IP protocols (VRRP, IGMP) require the --enable-extended-ip-protocols
					// flag to be set. These protocols do not use transport-layer ports.
					//
					// Matching on ICMP is not supported.
					//
					// Named port specified for a container may narrow this down, but may not
					// contradict this.
					protocol?: "TCP" | "UDP" | "SCTP" | "VRRP" | "IGMP" | "GRE" | "IPIP" | "IPV6" | "ESP" | "AH" | "ANY"
				}]
			}]
		}]

		// Labels is a list of optional strings which can be used to
		// re-identify the rule or to store metadata. It is possible to lookup
		// or delete strings based on labels. Labels are not required to be
		// unique, multiple rules can have overlapping or identical labels.
		labels?: [...{
			key!: string

			// Source can be one of the above values (e.g.: LabelSourceK8s).
			source?: string
			value?:  string
		}]

		// Log specifies custom policy-specific Hubble logging configuration.
		log?: {
			// Value is a free-form string that is included in Hubble flows
			// that match this policy. The string is limited to 32 printable characters.
			value?: =~"^\\PC*$"
		}

		// NodeSelector selects all nodes which should be subject to this rule.
		// EndpointSelector and NodeSelector cannot be both empty and are mutually
		// exclusive. Can only be used in CiliumClusterwideNetworkPolicies.
		nodeSelector?: {
			// matchExpressions is a list of label selector requirements. The requirements are ANDed.
			matchExpressions?: [...{
				// key is the label key that the selector applies to.
				key!: string

				// operator represents a key's relationship to a set of values.
				// Valid operators are In, NotIn, Exists and DoesNotExist.
				operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

				// values is an array of string values. If the operator is In or NotIn,
				// the values array must be non-empty. If the operator is Exists or DoesNotExist,
				// the values array must be empty. This array is replaced during a strategic
				// merge patch.
				values?: [...string]
			}]

			// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
			// map is equivalent to an element of matchExpressions, whose key field is "key", the
			// operator is "In", and the values array contains only "value". The requirements are ANDed.
			matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
		}
	}

	// Specs is a list of desired Cilium specific rule specification.
	specs?: [...{
		// Description is a free form string, it can be used by the creator of
		// the rule to store human readable explanation of the purpose of this
		// rule. Rules cannot be identified by comment.
		description?: string

		// Egress is a list of EgressRule which are enforced at egress.
		// If omitted or empty, this rule does not apply at egress.
		egress?: [...{
			// Authentication is the required authentication type for the allowed traffic, if any.
			authentication?: {
				// Mode is the required authentication mode for the allowed traffic, if any.
				mode!: "disabled" | "required" | "test-always-fail"
			}

			// ICMPs is a list of ICMP rule identified by type number
			// which the endpoint subject to the rule is allowed to connect to.
			//
			// Example:
			// Any endpoint with the label "app=httpd" is allowed to initiate
			// type 8 ICMP connections.
			icmps?: [...{
				// Fields is a list of ICMP fields.
				fields?: [...{
					// Family is a IP address version.
					// Currently, we support `IPv4` and `IPv6`.
					// `IPv4` is set as default.
					family?: "IPv4" | "IPv6"

					// Type is a ICMP-type.
					// It should be an 8bit code (0-255), or it's CamelCase name (for example, "EchoReply").
					// Allowed ICMP types are:
					// Ipv4: EchoReply | DestinationUnreachable | Redirect | Echo | EchoRequest |
					// RouterAdvertisement | RouterSelection | TimeExceeded | ParameterProblem |
					// Timestamp | TimestampReply | Photuris | ExtendedEcho Request | ExtendedEcho Reply
					// Ipv6: DestinationUnreachable | PacketTooBig | TimeExceeded | ParameterProblem |
					// EchoRequest | EchoReply | MulticastListenerQuery| MulticastListenerReport |
					// MulticastListenerDone | RouterSolicitation | RouterAdvertisement | NeighborSolicitation |
					// NeighborAdvertisement | RedirectMessage | RouterRenumbering | ICMPNodeInformationQuery |
					// ICMPNodeInformationResponse | InverseNeighborDiscoverySolicitation |
					// InverseNeighborDiscoveryAdvertisement |
					// HomeAgentAddressDiscoveryRequest | HomeAgentAddressDiscoveryReply | MobilePrefixSolicitation |
					// MobilePrefixAdvertisement | DuplicateAddressRequestCodeSuffix |
					// DuplicateAddressConfirmationCodeSuffix |
					// ExtendedEchoRequest | ExtendedEchoReply
					type!: (int |
						=~"^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]|EchoReply|DestinationUnreachable|Redirect|Echo|RouterAdvertisement|RouterSelection|TimeExceeded|ParameterProblem|Timestamp|TimestampReply|Photuris|ExtendedEchoRequest|ExtendedEcho Reply|PacketTooBig|ParameterProblem|EchoRequest|MulticastListenerQuery|MulticastListenerReport|MulticastListenerDone|RouterSolicitation|RouterAdvertisement|NeighborSolicitation|NeighborAdvertisement|RedirectMessage|RouterRenumbering|ICMPNodeInformationQuery|ICMPNodeInformationResponse|InverseNeighborDiscoverySolicitation|InverseNeighborDiscoveryAdvertisement|HomeAgentAddressDiscoveryRequest|HomeAgentAddressDiscoveryReply|MobilePrefixSolicitation|MobilePrefixAdvertisement|DuplicateAddressRequestCodeSuffix|DuplicateAddressConfirmationCodeSuffix)$")
				}]
			}]

			// ToCIDR is a list of IP blocks which the endpoint subject to the rule
			// is allowed to initiate connections. Only connections destined for
			// outside of the cluster and not targeting the host will be subject
			// to CIDR rules. This will match on the destination IP address of
			// outgoing connections. Adding a prefix into ToCIDR or into ToCIDRSet
			// with no ExcludeCIDRs is equivalent. Overlaps are allowed between
			// ToCIDR and ToCIDRSet.
			//
			// Example:
			// Any endpoint with the label "app=database-proxy" is allowed to
			// initiate connections to 10.2.3.0/24
			toCIDR?: [...string]

			// ToCIDRSet is a list of IP blocks which the endpoint subject to the rule
			// is allowed to initiate connections to in addition to connections
			// which are allowed via ToEndpoints, along with a list of subnets contained
			// within their corresponding IP block to which traffic should not be
			// allowed. This will match on the destination IP address of outgoing
			// connections. Adding a prefix into ToCIDR or into ToCIDRSet with no
			// ExcludeCIDRs is equivalent. Overlaps are allowed between ToCIDR and
			// ToCIDRSet.
			//
			// Example:
			// Any endpoint with the label "app=database-proxy" is allowed to
			// initiate connections to 10.2.3.0/24 except from IPs in subnet 10.2.3.0/28.
			toCIDRSet?: [...{
				// CIDR is a CIDR prefix / IP Block.
				cidr?: string

				// CIDRGroupRef is a reference to a CiliumCIDRGroup object.
				// A CiliumCIDRGroup contains a list of CIDRs that the endpoint, subject to
				// the rule, can (Ingress/Egress) or cannot (IngressDeny/EgressDeny) receive
				// connections from.
				cidrGroupRef?: =~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"

				// CIDRGroupSelector selects CiliumCIDRGroups by their labels,
				// rather than by name.
				cidrGroupSelector?: {
					// matchExpressions is a list of label selector requirements. The requirements are ANDed.
					matchExpressions?: [...{
						// key is the label key that the selector applies to.
						key!: string

						// operator represents a key's relationship to a set of values.
						// Valid operators are In, NotIn, Exists and DoesNotExist.
						operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

						// values is an array of string values. If the operator is In or NotIn,
						// the values array must be non-empty. If the operator is Exists or DoesNotExist,
						// the values array must be empty. This array is replaced during a strategic
						// merge patch.
						values?: [...string]
					}]

					// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
					// map is equivalent to an element of matchExpressions, whose key field is "key", the
					// operator is "In", and the values array contains only "value". The requirements are ANDed.
					matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
				}

				// ExceptCIDRs is a list of IP blocks which the endpoint subject to the rule
				// is not allowed to initiate connections to. These CIDR prefixes should be
				// contained within Cidr, using ExceptCIDRs together with CIDRGroupRef is not
				// supported yet.
				// These exceptions are only applied to the Cidr in this CIDRRule, and do not
				// apply to any other CIDR prefixes in any other CIDRRules.
				except?: [...string]
			}]

			// ToEndpoints is a list of endpoints identified by an EndpointSelector to
			// which the endpoints subject to the rule are allowed to communicate.
			//
			// Example:
			// Any endpoint with the label "role=frontend" can communicate with any
			// endpoint carrying the label "role=backend".
			//
			// Note that while an empty non-nil ToEndpoints does not select anything,
			// nil ToEndpoints is implicitly treated as a wildcard selector if ToPorts
			// are also specified.
			// To select everything, use one EndpointSelector without any match requirements.
			toEndpoints?: [...{
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
			}]

			// ToEntities is a list of special entities to which the endpoint subject
			// to the rule is allowed to initiate connections. Supported entities are
			// `world`, `cluster`, `cluster-mesh`, `host`, `remote-node`, `kube-apiserver`, `ingress`, `init`,
			// `health`, `unmanaged`, `none` and `all`.
			toEntities?: [
				..."all" |
					"world" |
					"cluster" |
					"cluster-mesh" |
					"host" |
					"init" |
					"ingress" |
					"unmanaged" |
					"remote-node" |
					"health" |
					"none" |
					"kube-apiserver",
			]

			// ToFQDN allows whitelisting DNS names in place of IPs. The IPs that result
			// from DNS resolution of `ToFQDN.MatchName`s are added to the same
			// EgressRule object as ToCIDRSet entries, and behave accordingly. Any L4 and
			// L7 rules within this EgressRule will also apply to these IPs.
			// The DNS -> IP mapping is re-resolved periodically from within the
			// cilium-agent, and the IPs in the DNS response are effected in the policy
			// for selected pods as-is (i.e. the list of IPs is not modified in any way).
			// Note: An explicit rule to allow for DNS traffic is needed for the pods, as
			// ToFQDN counts as an egress rule and will enforce egress policy when
			// PolicyEnforcment=default.
			// Note: If the resolved IPs are IPs within the kubernetes cluster, the
			// ToFQDN rule will not apply to that IP.
			// Note: ToFQDN cannot occur in the same policy as other To* rules.
			toFQDNs?: [...{
				// MatchName matches literal DNS names. A trailing "." is automatically added
				// when missing.
				matchName?: =~"^([-a-zA-Z0-9_]+[.]?)+$"

				// MatchPattern allows using wildcards to match DNS names. All wildcards are
				// case insensitive. The wildcards are:
				// - "*" matches 0 or more DNS valid characters, and may occur anywhere in
				// the pattern. As a special case a "*" as the leftmost character, without a
				// following "." matches all subdomains as well as the name to the right.
				// A trailing "." is automatically added when missing.
				// - "**." is a special prefix which matches all multilevel subdomains in the prefix.
				//
				// Examples:
				// 1. `*.cilium.io` matches subdomains of cilium at that level
				// www.cilium.io and blog.cilium.io match, cilium.io and google.com do not
				// 2. `*cilium.io` matches cilium.io and all subdomains ends with "cilium.io"
				// except those containing "." separator, subcilium.io and sub-cilium.io match,
				// www.cilium.io and blog.cilium.io does not
				// 3. `sub*.cilium.io` matches subdomains of cilium where the subdomain component
				// begins with "sub". sub.cilium.io and subdomain.cilium.io match while www.cilium.io,
				// blog.cilium.io, cilium.io and google.com do not
				// 4. `**.cilium.io` matches all multilevel subdomains of cilium.io.
				// "app.cilium.io" and "test.app.cilium.io" match but not "cilium.io"
				matchPattern?: =~"^([-a-zA-Z0-9_*]+[.]?)+$"
			}]

			// ToGroups allows policies to reference CIDRs provided by external integrations.
			// Currently, only AWS is supported, and the rule can select by multiple sub directives.
			// ToGroups entries are functionally equivalent to toCIDR, and have the same
			// limitiations. They cannot select traffic originating from within the cluster.
			//
			// Example:
			// toGroups:
			// - aws:
			// securityGroupsIds:
			// - 'sg-XXXXXXXXXXXXX'
			toGroups?: [...{
				// AWSGroup is an structure that can be used to whitelisting information from AWS integration
				aws?: {
					// Labels selects AWS ENIs by labels.
					// Multiple labels are AND-ed together.
					labels?: [string]: string

					// Deprecated: Region is unused.
					region?: string

					// SecurityGroupsIds selects VPC SecurityGroups by IDs.
					// If multiple IDs are specified, they are OR-ed together.
					//
					// Note that this may be AND-ed with any Names specified. Specifying both
					// IDs and Names is not recommended.
					securityGroupsIds?: [...string]

					// SecurityGroupsNames selects VPC SecurityGroups by name.
					// If multiple names are specified, they are OR-ed together.
					//
					// Note that this may be AND-ed with any IDs specified. Specifying both
					// IDs and Names is not recommended.
					securityGroupsNames?: [...string]
				}
			}]

			// ToNodes is a list of nodes identified by an
			// EndpointSelector to which endpoints subject to the rule is allowed to communicate.
			toNodes?: [...{
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
			}]

			// ToPorts is a list of destination ports identified by port number and
			// protocol which the endpoint subject to the rule is allowed to
			// connect to.
			//
			// Example:
			// Any endpoint with the label "role=frontend" is allowed to initiate
			// connections to destination port 8080/tcp
			toPorts?: [...{
				// listener specifies the name of a custom Envoy listener to which this traffic should be
				// redirected to.
				listener?: {
					// EnvoyConfig is a reference to the CEC or CCEC resource in which
					// the listener is defined.
					envoyConfig!: {
						// Kind is the resource type being referred to. Defaults to CiliumEnvoyConfig or
						// CiliumClusterwideEnvoyConfig for CiliumNetworkPolicy and CiliumClusterwideNetworkPolicy,
						// respectively. The only case this is currently explicitly needed is when referring to a
						// CiliumClusterwideEnvoyConfig from CiliumNetworkPolicy, as using a namespaced listener
						// from a cluster scoped policy is not allowed.
						kind?: "CiliumEnvoyConfig" | "CiliumClusterwideEnvoyConfig"

						// Name is the resource name of the CiliumEnvoyConfig or CiliumClusterwideEnvoyConfig where
						// the listener is defined in.
						name!: string
					}

					// Name is the name of the listener.
					name!: string

					// Priority for this Listener that is used when multiple rules would apply different
					// listeners to a policy map entry. Behavior of this is implementation dependent.
					priority?: int & <=100 & >=1
				}

				// OriginatingTLS is the TLS context for the connections originated by
				// the L7 proxy. For egress policy this specifies the client-side TLS
				// parameters for the upstream connection originating from the L7 proxy
				// to the remote destination. For ingress policy this specifies the
				// client-side TLS parameters for the connection from the L7 proxy to
				// the local endpoint.
				originatingTLS?: {
					// Certificate is the file name or k8s secret item name for the certificate
					// chain. If omitted, 'tls.crt' is assumed, if it exists. If given, the
					// item must exist.
					certificate?: string

					// PrivateKey is the file name or k8s secret item name for the private key
					// matching the certificate chain. If omitted, 'tls.key' is assumed, if it
					// exists. If given, the item must exist.
					privateKey?: string

					// Secret is the secret that contains the certificates and private key for
					// the TLS context.
					// By default, Cilium will search in this secret for the following items:
					// - 'ca.crt' - Which represents the trusted CA to verify remote source.
					// - 'tls.crt' - Which represents the public key certificate.
					// - 'tls.key' - Which represents the private key matching the public key
					// certificate.
					secret!: {
						// Name is the name of the secret.
						name!: string

						// Namespace is the namespace in which the secret exists. Context of use
						// determines the default value if left out (e.g., "default").
						namespace?: string
					}

					// TrustedCA is the file name or k8s secret item name for the trusted CA.
					// If omitted, 'ca.crt' is assumed, if it exists. If given, the item must
					// exist.
					trustedCA?: string
				}

				// Ports is a list of L4 port/protocol
				ports?: [...{
					// EndPort can only be an L4 port number.
					endPort?: int32 & int & <=65535 & >=0

					// Port can be an L4 port number, or a name in the form of "http"
					// or "http-8080".
					port?:
						=~"^(6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[0-9]{1,4})|([a-zA-Z0-9]-?)*[a-zA-Z](-?[a-zA-Z0-9])*$"

					// Protocol is the L4 protocol. If "ANY", omitted or empty, any protocols
					// with transport ports (TCP, UDP, SCTP) match.
					//
					// Accepted values: "TCP", "UDP", "SCTP", "VRRP", "IGMP", "GRE", "IPIP",
					// "IPV6", "ESP", "AH", "ANY"
					//
					// Tunnel/encapsulation protocols (GRE, IPIP, IPV6, ESP, AH) and other
					// extended IP protocols (VRRP, IGMP) require the --enable-extended-ip-protocols
					// flag to be set. These protocols do not use transport-layer ports.
					//
					// Matching on ICMP is not supported.
					//
					// Named port specified for a container may narrow this down, but may not
					// contradict this.
					protocol?: "TCP" | "UDP" | "SCTP" | "VRRP" | "IGMP" | "GRE" | "IPIP" | "IPV6" | "ESP" | "AH" | "ANY"
				}]

				// Rules is a list of additional port level rules which must be met in
				// order for the PortRule to allow the traffic. If omitted or empty,
				// no layer 7 rules are enforced.
				rules?: {
					// DNS-specific rules.
					dns?: [...{
						// MatchName matches literal DNS names. A trailing "." is automatically added
						// when missing.
						matchName?: =~"^([-a-zA-Z0-9_]+[.]?)+$"

						// MatchPattern allows using wildcards to match DNS names. All wildcards are
						// case insensitive. The wildcards are:
						// - "*" matches 0 or more DNS valid characters, and may occur anywhere in
						// the pattern. As a special case a "*" as the leftmost character, without a
						// following "." matches all subdomains as well as the name to the right.
						// A trailing "." is automatically added when missing.
						// - "**." is a special prefix which matches all multilevel subdomains in the prefix.
						//
						// Examples:
						// 1. `*.cilium.io` matches subdomains of cilium at that level
						// www.cilium.io and blog.cilium.io match, cilium.io and google.com do not
						// 2. `*cilium.io` matches cilium.io and all subdomains ends with "cilium.io"
						// except those containing "." separator, subcilium.io and sub-cilium.io match,
						// www.cilium.io and blog.cilium.io does not
						// 3. `sub*.cilium.io` matches subdomains of cilium where the subdomain component
						// begins with "sub". sub.cilium.io and subdomain.cilium.io match while www.cilium.io,
						// blog.cilium.io, cilium.io and google.com do not
						// 4. `**.cilium.io` matches all multilevel subdomains of cilium.io.
						// "app.cilium.io" and "test.app.cilium.io" match but not "cilium.io"
						matchPattern?: =~"^([-a-zA-Z0-9_*]+[.]?)+$"
					}]

					// HTTP specific rules.
					http?: [...{
						// HeaderMatches is a list of HTTP headers which must be
						// present and match against the given values. Mismatch field can be used
						// to specify what to do when there is no match.
						headerMatches?: [...{
							// Mismatch identifies what to do in case there is no match. The default is
							// to drop the request. Otherwise the overall rule is still considered as
							// matching, but the mismatches are logged in the access log.
							mismatch?: "LOG" | "ADD" | "DELETE" | "REPLACE"

							// Name identifies the header.
							name!: string

							// Secret refers to a secret that contains the value to be matched against.
							// The secret must only contain one entry. If the referred secret does not
							// exist, and there is no "Value" specified, the match will fail.
							secret?: {
								// Name is the name of the secret.
								name!: string

								// Namespace is the namespace in which the secret exists. Context of use
								// determines the default value if left out (e.g., "default").
								namespace?: string
							}

							// Value matches the exact value of the header. Can be specified either
							// alone or together with "Secret"; will be used as the header value if the
							// secret can not be found in the latter case.
							value?: string
						}]

						// Headers is a list of HTTP headers which must be present in the
						// request. If omitted or empty, requests are allowed regardless of
						// headers present.
						headers?: [...string]

						// Host is an extended POSIX regex matched against the host header of a
						// request. Examples:
						//
						// - foo.bar.com will match the host fooXbar.com or foo-bar.com
						// - foo\.bar\.com will only match the host foo.bar.com
						//
						// If omitted or empty, the value of the host header is ignored.
						host?: string

						// Method is an extended POSIX regex matched against the method of a
						// request, e.g. "GET", "POST", "PUT", "PATCH", "DELETE", ...
						//
						// If omitted or empty, all methods are allowed.
						method?: string

						// Path is an extended POSIX regex matched against the path of a
						// request. Currently it can contain characters disallowed from the
						// conventional "path" part of a URL as defined by RFC 3986.
						//
						// If omitted or empty, all paths are all allowed.
						path?: string
					}]
				}

				// ServerNames is a list of allowed TLS SNI values. If not empty, then
				// TLS must be present and one of the provided SNIs must be indicated in the
				// TLS handshake.
				serverNames?: [...=~"^([-a-zA-Z0-9_*]+[.]?)+$"]

				// TerminatingTLS is the TLS context for the connection terminated by
				// the L7 proxy. For egress policy this specifies the server-side TLS
				// parameters to be applied on the connections originated from the local
				// endpoint and terminated by the L7 proxy. For ingress policy this specifies
				// the server-side TLS parameters to be applied on the connections
				// originated from a remote source and terminated by the L7 proxy.
				terminatingTLS?: {
					// Certificate is the file name or k8s secret item name for the certificate
					// chain. If omitted, 'tls.crt' is assumed, if it exists. If given, the
					// item must exist.
					certificate?: string

					// PrivateKey is the file name or k8s secret item name for the private key
					// matching the certificate chain. If omitted, 'tls.key' is assumed, if it
					// exists. If given, the item must exist.
					privateKey?: string

					// Secret is the secret that contains the certificates and private key for
					// the TLS context.
					// By default, Cilium will search in this secret for the following items:
					// - 'ca.crt' - Which represents the trusted CA to verify remote source.
					// - 'tls.crt' - Which represents the public key certificate.
					// - 'tls.key' - Which represents the private key matching the public key
					// certificate.
					secret!: {
						// Name is the name of the secret.
						name!: string

						// Namespace is the namespace in which the secret exists. Context of use
						// determines the default value if left out (e.g., "default").
						namespace?: string
					}

					// TrustedCA is the file name or k8s secret item name for the trusted CA.
					// If omitted, 'ca.crt' is assumed, if it exists. If given, the item must
					// exist.
					trustedCA?: string
				}
			}]

			// Deprecated.
			toRequires?: [...string]

			// ToServices is a list of services to which the endpoint subject
			// to the rule is allowed to initiate connections.
			// Currently Cilium only supports toServices for K8s services.
			toServices?: [...{
				// K8sService selects service by name and namespace pair
				k8sService?: {
					namespace?:   string
					serviceName?: string
				}

				// K8sServiceSelector selects services by k8s labels and namespace
				k8sServiceSelector?: {
					namespace?: string

					// ServiceSelector is a label selector for k8s services
					selector!: {
						// matchExpressions is a list of label selector requirements. The requirements are ANDed.
						matchExpressions?: [...{
							// key is the label key that the selector applies to.
							key!: string

							// operator represents a key's relationship to a set of values.
							// Valid operators are In, NotIn, Exists and DoesNotExist.
							operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

							// values is an array of string values. If the operator is In or NotIn,
							// the values array must be non-empty. If the operator is Exists or DoesNotExist,
							// the values array must be empty. This array is replaced during a strategic
							// merge patch.
							values?: [...string]
						}]

						// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
						// map is equivalent to an element of matchExpressions, whose key field is "key", the
						// operator is "In", and the values array contains only "value". The requirements are ANDed.
						matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
					}
				}
			}]
		}]

		// EgressDeny is a list of EgressDenyRule which are enforced at egress.
		// Any rule inserted here will be denied regardless of the allowed egress
		// rules in the 'egress' field.
		// If omitted or empty, this rule does not apply at egress.
		egressDeny?: [...{
			// ICMPs is a list of ICMP rule identified by type number
			// which the endpoint subject to the rule is not allowed to connect to.
			//
			// Example:
			// Any endpoint with the label "app=httpd" is not allowed to initiate
			// type 8 ICMP connections.
			icmps?: [...{
				// Fields is a list of ICMP fields.
				fields?: [...{
					// Family is a IP address version.
					// Currently, we support `IPv4` and `IPv6`.
					// `IPv4` is set as default.
					family?: "IPv4" | "IPv6"

					// Type is a ICMP-type.
					// It should be an 8bit code (0-255), or it's CamelCase name (for example, "EchoReply").
					// Allowed ICMP types are:
					// Ipv4: EchoReply | DestinationUnreachable | Redirect | Echo | EchoRequest |
					// RouterAdvertisement | RouterSelection | TimeExceeded | ParameterProblem |
					// Timestamp | TimestampReply | Photuris | ExtendedEcho Request | ExtendedEcho Reply
					// Ipv6: DestinationUnreachable | PacketTooBig | TimeExceeded | ParameterProblem |
					// EchoRequest | EchoReply | MulticastListenerQuery| MulticastListenerReport |
					// MulticastListenerDone | RouterSolicitation | RouterAdvertisement | NeighborSolicitation |
					// NeighborAdvertisement | RedirectMessage | RouterRenumbering | ICMPNodeInformationQuery |
					// ICMPNodeInformationResponse | InverseNeighborDiscoverySolicitation |
					// InverseNeighborDiscoveryAdvertisement |
					// HomeAgentAddressDiscoveryRequest | HomeAgentAddressDiscoveryReply | MobilePrefixSolicitation |
					// MobilePrefixAdvertisement | DuplicateAddressRequestCodeSuffix |
					// DuplicateAddressConfirmationCodeSuffix |
					// ExtendedEchoRequest | ExtendedEchoReply
					type!: (int |
						=~"^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]|EchoReply|DestinationUnreachable|Redirect|Echo|RouterAdvertisement|RouterSelection|TimeExceeded|ParameterProblem|Timestamp|TimestampReply|Photuris|ExtendedEchoRequest|ExtendedEcho Reply|PacketTooBig|ParameterProblem|EchoRequest|MulticastListenerQuery|MulticastListenerReport|MulticastListenerDone|RouterSolicitation|RouterAdvertisement|NeighborSolicitation|NeighborAdvertisement|RedirectMessage|RouterRenumbering|ICMPNodeInformationQuery|ICMPNodeInformationResponse|InverseNeighborDiscoverySolicitation|InverseNeighborDiscoveryAdvertisement|HomeAgentAddressDiscoveryRequest|HomeAgentAddressDiscoveryReply|MobilePrefixSolicitation|MobilePrefixAdvertisement|DuplicateAddressRequestCodeSuffix|DuplicateAddressConfirmationCodeSuffix)$")
				}]
			}]

			// ToCIDR is a list of IP blocks which the endpoint subject to the rule
			// is allowed to initiate connections. Only connections destined for
			// outside of the cluster and not targeting the host will be subject
			// to CIDR rules. This will match on the destination IP address of
			// outgoing connections. Adding a prefix into ToCIDR or into ToCIDRSet
			// with no ExcludeCIDRs is equivalent. Overlaps are allowed between
			// ToCIDR and ToCIDRSet.
			//
			// Example:
			// Any endpoint with the label "app=database-proxy" is allowed to
			// initiate connections to 10.2.3.0/24
			toCIDR?: [...string]

			// ToCIDRSet is a list of IP blocks which the endpoint subject to the rule
			// is allowed to initiate connections to in addition to connections
			// which are allowed via ToEndpoints, along with a list of subnets contained
			// within their corresponding IP block to which traffic should not be
			// allowed. This will match on the destination IP address of outgoing
			// connections. Adding a prefix into ToCIDR or into ToCIDRSet with no
			// ExcludeCIDRs is equivalent. Overlaps are allowed between ToCIDR and
			// ToCIDRSet.
			//
			// Example:
			// Any endpoint with the label "app=database-proxy" is allowed to
			// initiate connections to 10.2.3.0/24 except from IPs in subnet 10.2.3.0/28.
			toCIDRSet?: [...{
				// CIDR is a CIDR prefix / IP Block.
				cidr?: string

				// CIDRGroupRef is a reference to a CiliumCIDRGroup object.
				// A CiliumCIDRGroup contains a list of CIDRs that the endpoint, subject to
				// the rule, can (Ingress/Egress) or cannot (IngressDeny/EgressDeny) receive
				// connections from.
				cidrGroupRef?: =~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"

				// CIDRGroupSelector selects CiliumCIDRGroups by their labels,
				// rather than by name.
				cidrGroupSelector?: {
					// matchExpressions is a list of label selector requirements. The requirements are ANDed.
					matchExpressions?: [...{
						// key is the label key that the selector applies to.
						key!: string

						// operator represents a key's relationship to a set of values.
						// Valid operators are In, NotIn, Exists and DoesNotExist.
						operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

						// values is an array of string values. If the operator is In or NotIn,
						// the values array must be non-empty. If the operator is Exists or DoesNotExist,
						// the values array must be empty. This array is replaced during a strategic
						// merge patch.
						values?: [...string]
					}]

					// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
					// map is equivalent to an element of matchExpressions, whose key field is "key", the
					// operator is "In", and the values array contains only "value". The requirements are ANDed.
					matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
				}

				// ExceptCIDRs is a list of IP blocks which the endpoint subject to the rule
				// is not allowed to initiate connections to. These CIDR prefixes should be
				// contained within Cidr, using ExceptCIDRs together with CIDRGroupRef is not
				// supported yet.
				// These exceptions are only applied to the Cidr in this CIDRRule, and do not
				// apply to any other CIDR prefixes in any other CIDRRules.
				except?: [...string]
			}]

			// ToEndpoints is a list of endpoints identified by an EndpointSelector to
			// which the endpoints subject to the rule are allowed to communicate.
			//
			// Example:
			// Any endpoint with the label "role=frontend" can communicate with any
			// endpoint carrying the label "role=backend".
			//
			// Note that while an empty non-nil ToEndpoints does not select anything,
			// nil ToEndpoints is implicitly treated as a wildcard selector if ToPorts
			// are also specified.
			// To select everything, use one EndpointSelector without any match requirements.
			toEndpoints?: [...{
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
			}]

			// ToEntities is a list of special entities to which the endpoint subject
			// to the rule is allowed to initiate connections. Supported entities are
			// `world`, `cluster`, `cluster-mesh`, `host`, `remote-node`, `kube-apiserver`, `ingress`, `init`,
			// `health`, `unmanaged`, `none` and `all`.
			toEntities?: [
				..."all" |
					"world" |
					"cluster" |
					"cluster-mesh" |
					"host" |
					"init" |
					"ingress" |
					"unmanaged" |
					"remote-node" |
					"health" |
					"none" |
					"kube-apiserver",
			]

			// ToGroups allows policies to reference CIDRs provided by external integrations.
			// Currently, only AWS is supported, and the rule can select by multiple sub directives.
			// ToGroups entries are functionally equivalent to toCIDR, and have the same
			// limitiations. They cannot select traffic originating from within the cluster.
			//
			// Example:
			// toGroups:
			// - aws:
			// securityGroupsIds:
			// - 'sg-XXXXXXXXXXXXX'
			toGroups?: [...{
				// AWSGroup is an structure that can be used to whitelisting information from AWS integration
				aws?: {
					// Labels selects AWS ENIs by labels.
					// Multiple labels are AND-ed together.
					labels?: [string]: string

					// Deprecated: Region is unused.
					region?: string

					// SecurityGroupsIds selects VPC SecurityGroups by IDs.
					// If multiple IDs are specified, they are OR-ed together.
					//
					// Note that this may be AND-ed with any Names specified. Specifying both
					// IDs and Names is not recommended.
					securityGroupsIds?: [...string]

					// SecurityGroupsNames selects VPC SecurityGroups by name.
					// If multiple names are specified, they are OR-ed together.
					//
					// Note that this may be AND-ed with any IDs specified. Specifying both
					// IDs and Names is not recommended.
					securityGroupsNames?: [...string]
				}
			}]

			// ToNodes is a list of nodes identified by an
			// EndpointSelector to which endpoints subject to the rule is allowed to communicate.
			toNodes?: [...{
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
			}]

			// ToPorts is a list of destination ports identified by port number and
			// protocol which the endpoint subject to the rule is not allowed to connect
			// to.
			//
			// Example:
			// Any endpoint with the label "role=frontend" is not allowed to initiate
			// connections to destination port 8080/tcp
			toPorts?: [...{
				// Ports is a list of L4 port/protocol
				ports?: [...{
					// EndPort can only be an L4 port number.
					endPort?: int32 & int & <=65535 & >=0

					// Port can be an L4 port number, or a name in the form of "http"
					// or "http-8080".
					port?:
						=~"^(6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[0-9]{1,4})|([a-zA-Z0-9]-?)*[a-zA-Z](-?[a-zA-Z0-9])*$"

					// Protocol is the L4 protocol. If "ANY", omitted or empty, any protocols
					// with transport ports (TCP, UDP, SCTP) match.
					//
					// Accepted values: "TCP", "UDP", "SCTP", "VRRP", "IGMP", "GRE", "IPIP",
					// "IPV6", "ESP", "AH", "ANY"
					//
					// Tunnel/encapsulation protocols (GRE, IPIP, IPV6, ESP, AH) and other
					// extended IP protocols (VRRP, IGMP) require the --enable-extended-ip-protocols
					// flag to be set. These protocols do not use transport-layer ports.
					//
					// Matching on ICMP is not supported.
					//
					// Named port specified for a container may narrow this down, but may not
					// contradict this.
					protocol?: "TCP" | "UDP" | "SCTP" | "VRRP" | "IGMP" | "GRE" | "IPIP" | "IPV6" | "ESP" | "AH" | "ANY"
				}]
			}]

			// Deprecated.
			toRequires?: [...string]

			// ToServices is a list of services to which the endpoint subject
			// to the rule is allowed to initiate connections.
			// Currently Cilium only supports toServices for K8s services.
			toServices?: [...{
				// K8sService selects service by name and namespace pair
				k8sService?: {
					namespace?:   string
					serviceName?: string
				}

				// K8sServiceSelector selects services by k8s labels and namespace
				k8sServiceSelector?: {
					namespace?: string

					// ServiceSelector is a label selector for k8s services
					selector!: {
						// matchExpressions is a list of label selector requirements. The requirements are ANDed.
						matchExpressions?: [...{
							// key is the label key that the selector applies to.
							key!: string

							// operator represents a key's relationship to a set of values.
							// Valid operators are In, NotIn, Exists and DoesNotExist.
							operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

							// values is an array of string values. If the operator is In or NotIn,
							// the values array must be non-empty. If the operator is Exists or DoesNotExist,
							// the values array must be empty. This array is replaced during a strategic
							// merge patch.
							values?: [...string]
						}]

						// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
						// map is equivalent to an element of matchExpressions, whose key field is "key", the
						// operator is "In", and the values array contains only "value". The requirements are ANDed.
						matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
					}
				}
			}]
		}]

		// EnableDefaultDeny determines whether this policy configures the
		// subject endpoint(s) to have a default deny mode. If enabled,
		// this causes all traffic not explicitly allowed by a network policy
		// to be dropped.
		//
		// If not specified, the default is true for each traffic direction
		// that has rules, and false otherwise. For example, if a policy
		// only has Ingress or IngressDeny rules, then the default for
		// ingress is true and egress is false.
		//
		// If multiple policies apply to an endpoint, that endpoint's default deny
		// will be enabled if any policy requests it.
		//
		// This is useful for creating broad-based network policies that will not
		// cause endpoints to enter default-deny mode.
		enableDefaultDeny?: {
			// Whether or not the endpoint should have a default-deny rule applied
			// to egress traffic.
			egress?: bool

			// Whether or not the endpoint should have a default-deny rule applied
			// to ingress traffic.
			ingress?: bool
		}

		// EndpointSelector selects all endpoints which should be subject to
		// this rule. EndpointSelector and NodeSelector cannot be both empty and
		// are mutually exclusive.
		endpointSelector?: {
			// matchExpressions is a list of label selector requirements. The requirements are ANDed.
			matchExpressions?: [...{
				// key is the label key that the selector applies to.
				key!: string

				// operator represents a key's relationship to a set of values.
				// Valid operators are In, NotIn, Exists and DoesNotExist.
				operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

				// values is an array of string values. If the operator is In or NotIn,
				// the values array must be non-empty. If the operator is Exists or DoesNotExist,
				// the values array must be empty. This array is replaced during a strategic
				// merge patch.
				values?: [...string]
			}]

			// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
			// map is equivalent to an element of matchExpressions, whose key field is "key", the
			// operator is "In", and the values array contains only "value". The requirements are ANDed.
			matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
		}

		// Ingress is a list of IngressRule which are enforced at ingress.
		// If omitted or empty, this rule does not apply at ingress.
		ingress?: [...{
			// Authentication is the required authentication type for the allowed traffic, if any.
			authentication?: {
				// Mode is the required authentication mode for the allowed traffic, if any.
				mode!: "disabled" | "required" | "test-always-fail"
			}

			// FromCIDR is a list of IP blocks which the endpoint subject to the
			// rule is allowed to receive connections from. Only connections which
			// do *not* originate from the cluster or from the local host are subject
			// to CIDR rules. In order to allow in-cluster connectivity, use the
			// FromEndpoints field. This will match on the source IP address of
			// incoming connections. Adding a prefix into FromCIDR or into
			// FromCIDRSet with no ExcludeCIDRs is equivalent. Overlaps are
			// allowed between FromCIDR and FromCIDRSet.
			//
			// Example:
			// Any endpoint with the label "app=my-legacy-pet" is allowed to receive
			// connections from 10.3.9.1
			fromCIDR?: [...string]

			// FromCIDRSet is a list of IP blocks which the endpoint subject to the
			// rule is allowed to receive connections from in addition to FromEndpoints,
			// along with a list of subnets contained within their corresponding IP block
			// from which traffic should not be allowed.
			// This will match on the source IP address of incoming connections. Adding
			// a prefix into FromCIDR or into FromCIDRSet with no ExcludeCIDRs is
			// equivalent. Overlaps are allowed between FromCIDR and FromCIDRSet.
			//
			// Example:
			// Any endpoint with the label "app=my-legacy-pet" is allowed to receive
			// connections from 10.0.0.0/8 except from IPs in subnet 10.96.0.0/12.
			fromCIDRSet?: [...{
				// CIDR is a CIDR prefix / IP Block.
				cidr?: string

				// CIDRGroupRef is a reference to a CiliumCIDRGroup object.
				// A CiliumCIDRGroup contains a list of CIDRs that the endpoint, subject to
				// the rule, can (Ingress/Egress) or cannot (IngressDeny/EgressDeny) receive
				// connections from.
				cidrGroupRef?: =~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"

				// CIDRGroupSelector selects CiliumCIDRGroups by their labels,
				// rather than by name.
				cidrGroupSelector?: {
					// matchExpressions is a list of label selector requirements. The requirements are ANDed.
					matchExpressions?: [...{
						// key is the label key that the selector applies to.
						key!: string

						// operator represents a key's relationship to a set of values.
						// Valid operators are In, NotIn, Exists and DoesNotExist.
						operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

						// values is an array of string values. If the operator is In or NotIn,
						// the values array must be non-empty. If the operator is Exists or DoesNotExist,
						// the values array must be empty. This array is replaced during a strategic
						// merge patch.
						values?: [...string]
					}]

					// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
					// map is equivalent to an element of matchExpressions, whose key field is "key", the
					// operator is "In", and the values array contains only "value". The requirements are ANDed.
					matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
				}

				// ExceptCIDRs is a list of IP blocks which the endpoint subject to the rule
				// is not allowed to initiate connections to. These CIDR prefixes should be
				// contained within Cidr, using ExceptCIDRs together with CIDRGroupRef is not
				// supported yet.
				// These exceptions are only applied to the Cidr in this CIDRRule, and do not
				// apply to any other CIDR prefixes in any other CIDRRules.
				except?: [...string]
			}]

			// FromEndpoints is a list of endpoints identified by an
			// EndpointSelector which are allowed to communicate with the endpoint
			// subject to the rule.
			//
			// Example:
			// Any endpoint with the label "role=backend" can be consumed by any
			// endpoint carrying the label "role=frontend".
			//
			// Note that while an empty non-nil FromEndpoints does not select anything,
			// nil FromEndpoints is implicitly treated as a wildcard selector if ToPorts
			// are also specified.
			// To select everything, use one EndpointSelector without any match requirements.
			fromEndpoints?: [...{
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
			}]

			// FromEntities is a list of special entities which the endpoint subject
			// to the rule is allowed to receive connections from. Supported entities are
			// `world`, `cluster`, `cluster-mesh`, `host`, `remote-node`, `kube-apiserver`, `ingress`, `init`,
			// `health`, `unmanaged`, `none` and `all`.
			fromEntities?: [
				..."all" |
					"world" |
					"cluster" |
					"cluster-mesh" |
					"host" |
					"init" |
					"ingress" |
					"unmanaged" |
					"remote-node" |
					"health" |
					"none" |
					"kube-apiserver",
			]

			// FromGroups allows policies to reference CIDRs provided by external integrations.
			// Currently, only AWS is supported, and the rule can select by multiple sub directives.
			// FromGroups entries are functionally equivalent to FromCIDR, and have the same
			// limitiations. They cannot select traffic originating from within the cluster.
			//
			// Example:
			// fromGroups:
			// - aws:
			// securityGroupsIds:
			// - 'sg-XXXXXXXXXXXXX'
			fromGroups?: [...{
				// AWSGroup is an structure that can be used to whitelisting information from AWS integration
				aws?: {
					// Labels selects AWS ENIs by labels.
					// Multiple labels are AND-ed together.
					labels?: [string]: string

					// Deprecated: Region is unused.
					region?: string

					// SecurityGroupsIds selects VPC SecurityGroups by IDs.
					// If multiple IDs are specified, they are OR-ed together.
					//
					// Note that this may be AND-ed with any Names specified. Specifying both
					// IDs and Names is not recommended.
					securityGroupsIds?: [...string]

					// SecurityGroupsNames selects VPC SecurityGroups by name.
					// If multiple names are specified, they are OR-ed together.
					//
					// Note that this may be AND-ed with any IDs specified. Specifying both
					// IDs and Names is not recommended.
					securityGroupsNames?: [...string]
				}
			}]

			// FromNodes is a list of nodes identified by an
			// EndpointSelector which are allowed to communicate with the endpoint
			// subject to the rule.
			fromNodes?: [...{
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
			}]

			// Deprecated.
			fromRequires?: [...string]

			// ICMPs is a list of ICMP rule identified by type number
			// which the endpoint subject to the rule is allowed to
			// receive connections on.
			//
			// Example:
			// Any endpoint with the label "app=httpd" can only accept incoming
			// type 8 ICMP connections.
			icmps?: [...{
				// Fields is a list of ICMP fields.
				fields?: [...{
					// Family is a IP address version.
					// Currently, we support `IPv4` and `IPv6`.
					// `IPv4` is set as default.
					family?: "IPv4" | "IPv6"

					// Type is a ICMP-type.
					// It should be an 8bit code (0-255), or it's CamelCase name (for example, "EchoReply").
					// Allowed ICMP types are:
					// Ipv4: EchoReply | DestinationUnreachable | Redirect | Echo | EchoRequest |
					// RouterAdvertisement | RouterSelection | TimeExceeded | ParameterProblem |
					// Timestamp | TimestampReply | Photuris | ExtendedEcho Request | ExtendedEcho Reply
					// Ipv6: DestinationUnreachable | PacketTooBig | TimeExceeded | ParameterProblem |
					// EchoRequest | EchoReply | MulticastListenerQuery| MulticastListenerReport |
					// MulticastListenerDone | RouterSolicitation | RouterAdvertisement | NeighborSolicitation |
					// NeighborAdvertisement | RedirectMessage | RouterRenumbering | ICMPNodeInformationQuery |
					// ICMPNodeInformationResponse | InverseNeighborDiscoverySolicitation |
					// InverseNeighborDiscoveryAdvertisement |
					// HomeAgentAddressDiscoveryRequest | HomeAgentAddressDiscoveryReply | MobilePrefixSolicitation |
					// MobilePrefixAdvertisement | DuplicateAddressRequestCodeSuffix |
					// DuplicateAddressConfirmationCodeSuffix |
					// ExtendedEchoRequest | ExtendedEchoReply
					type!: (int |
						=~"^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]|EchoReply|DestinationUnreachable|Redirect|Echo|RouterAdvertisement|RouterSelection|TimeExceeded|ParameterProblem|Timestamp|TimestampReply|Photuris|ExtendedEchoRequest|ExtendedEcho Reply|PacketTooBig|ParameterProblem|EchoRequest|MulticastListenerQuery|MulticastListenerReport|MulticastListenerDone|RouterSolicitation|RouterAdvertisement|NeighborSolicitation|NeighborAdvertisement|RedirectMessage|RouterRenumbering|ICMPNodeInformationQuery|ICMPNodeInformationResponse|InverseNeighborDiscoverySolicitation|InverseNeighborDiscoveryAdvertisement|HomeAgentAddressDiscoveryRequest|HomeAgentAddressDiscoveryReply|MobilePrefixSolicitation|MobilePrefixAdvertisement|DuplicateAddressRequestCodeSuffix|DuplicateAddressConfirmationCodeSuffix)$")
				}]
			}]

			// ToPorts is a list of destination ports identified by port number and
			// protocol which the endpoint subject to the rule is allowed to
			// receive connections on.
			//
			// Example:
			// Any endpoint with the label "app=httpd" can only accept incoming
			// connections on port 80/tcp.
			toPorts?: [...{
				// listener specifies the name of a custom Envoy listener to which this traffic should be
				// redirected to.
				listener?: {
					// EnvoyConfig is a reference to the CEC or CCEC resource in which
					// the listener is defined.
					envoyConfig!: {
						// Kind is the resource type being referred to. Defaults to CiliumEnvoyConfig or
						// CiliumClusterwideEnvoyConfig for CiliumNetworkPolicy and CiliumClusterwideNetworkPolicy,
						// respectively. The only case this is currently explicitly needed is when referring to a
						// CiliumClusterwideEnvoyConfig from CiliumNetworkPolicy, as using a namespaced listener
						// from a cluster scoped policy is not allowed.
						kind?: "CiliumEnvoyConfig" | "CiliumClusterwideEnvoyConfig"

						// Name is the resource name of the CiliumEnvoyConfig or CiliumClusterwideEnvoyConfig where
						// the listener is defined in.
						name!: string
					}

					// Name is the name of the listener.
					name!: string

					// Priority for this Listener that is used when multiple rules would apply different
					// listeners to a policy map entry. Behavior of this is implementation dependent.
					priority?: int & <=100 & >=1
				}

				// OriginatingTLS is the TLS context for the connections originated by
				// the L7 proxy. For egress policy this specifies the client-side TLS
				// parameters for the upstream connection originating from the L7 proxy
				// to the remote destination. For ingress policy this specifies the
				// client-side TLS parameters for the connection from the L7 proxy to
				// the local endpoint.
				originatingTLS?: {
					// Certificate is the file name or k8s secret item name for the certificate
					// chain. If omitted, 'tls.crt' is assumed, if it exists. If given, the
					// item must exist.
					certificate?: string

					// PrivateKey is the file name or k8s secret item name for the private key
					// matching the certificate chain. If omitted, 'tls.key' is assumed, if it
					// exists. If given, the item must exist.
					privateKey?: string

					// Secret is the secret that contains the certificates and private key for
					// the TLS context.
					// By default, Cilium will search in this secret for the following items:
					// - 'ca.crt' - Which represents the trusted CA to verify remote source.
					// - 'tls.crt' - Which represents the public key certificate.
					// - 'tls.key' - Which represents the private key matching the public key
					// certificate.
					secret!: {
						// Name is the name of the secret.
						name!: string

						// Namespace is the namespace in which the secret exists. Context of use
						// determines the default value if left out (e.g., "default").
						namespace?: string
					}

					// TrustedCA is the file name or k8s secret item name for the trusted CA.
					// If omitted, 'ca.crt' is assumed, if it exists. If given, the item must
					// exist.
					trustedCA?: string
				}

				// Ports is a list of L4 port/protocol
				ports?: [...{
					// EndPort can only be an L4 port number.
					endPort?: int32 & int & <=65535 & >=0

					// Port can be an L4 port number, or a name in the form of "http"
					// or "http-8080".
					port?:
						=~"^(6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[0-9]{1,4})|([a-zA-Z0-9]-?)*[a-zA-Z](-?[a-zA-Z0-9])*$"

					// Protocol is the L4 protocol. If "ANY", omitted or empty, any protocols
					// with transport ports (TCP, UDP, SCTP) match.
					//
					// Accepted values: "TCP", "UDP", "SCTP", "VRRP", "IGMP", "GRE", "IPIP",
					// "IPV6", "ESP", "AH", "ANY"
					//
					// Tunnel/encapsulation protocols (GRE, IPIP, IPV6, ESP, AH) and other
					// extended IP protocols (VRRP, IGMP) require the --enable-extended-ip-protocols
					// flag to be set. These protocols do not use transport-layer ports.
					//
					// Matching on ICMP is not supported.
					//
					// Named port specified for a container may narrow this down, but may not
					// contradict this.
					protocol?: "TCP" | "UDP" | "SCTP" | "VRRP" | "IGMP" | "GRE" | "IPIP" | "IPV6" | "ESP" | "AH" | "ANY"
				}]

				// Rules is a list of additional port level rules which must be met in
				// order for the PortRule to allow the traffic. If omitted or empty,
				// no layer 7 rules are enforced.
				rules?: {
					// DNS-specific rules.
					dns?: [...{
						// MatchName matches literal DNS names. A trailing "." is automatically added
						// when missing.
						matchName?: =~"^([-a-zA-Z0-9_]+[.]?)+$"

						// MatchPattern allows using wildcards to match DNS names. All wildcards are
						// case insensitive. The wildcards are:
						// - "*" matches 0 or more DNS valid characters, and may occur anywhere in
						// the pattern. As a special case a "*" as the leftmost character, without a
						// following "." matches all subdomains as well as the name to the right.
						// A trailing "." is automatically added when missing.
						// - "**." is a special prefix which matches all multilevel subdomains in the prefix.
						//
						// Examples:
						// 1. `*.cilium.io` matches subdomains of cilium at that level
						// www.cilium.io and blog.cilium.io match, cilium.io and google.com do not
						// 2. `*cilium.io` matches cilium.io and all subdomains ends with "cilium.io"
						// except those containing "." separator, subcilium.io and sub-cilium.io match,
						// www.cilium.io and blog.cilium.io does not
						// 3. `sub*.cilium.io` matches subdomains of cilium where the subdomain component
						// begins with "sub". sub.cilium.io and subdomain.cilium.io match while www.cilium.io,
						// blog.cilium.io, cilium.io and google.com do not
						// 4. `**.cilium.io` matches all multilevel subdomains of cilium.io.
						// "app.cilium.io" and "test.app.cilium.io" match but not "cilium.io"
						matchPattern?: =~"^([-a-zA-Z0-9_*]+[.]?)+$"
					}]

					// HTTP specific rules.
					http?: [...{
						// HeaderMatches is a list of HTTP headers which must be
						// present and match against the given values. Mismatch field can be used
						// to specify what to do when there is no match.
						headerMatches?: [...{
							// Mismatch identifies what to do in case there is no match. The default is
							// to drop the request. Otherwise the overall rule is still considered as
							// matching, but the mismatches are logged in the access log.
							mismatch?: "LOG" | "ADD" | "DELETE" | "REPLACE"

							// Name identifies the header.
							name!: string

							// Secret refers to a secret that contains the value to be matched against.
							// The secret must only contain one entry. If the referred secret does not
							// exist, and there is no "Value" specified, the match will fail.
							secret?: {
								// Name is the name of the secret.
								name!: string

								// Namespace is the namespace in which the secret exists. Context of use
								// determines the default value if left out (e.g., "default").
								namespace?: string
							}

							// Value matches the exact value of the header. Can be specified either
							// alone or together with "Secret"; will be used as the header value if the
							// secret can not be found in the latter case.
							value?: string
						}]

						// Headers is a list of HTTP headers which must be present in the
						// request. If omitted or empty, requests are allowed regardless of
						// headers present.
						headers?: [...string]

						// Host is an extended POSIX regex matched against the host header of a
						// request. Examples:
						//
						// - foo.bar.com will match the host fooXbar.com or foo-bar.com
						// - foo\.bar\.com will only match the host foo.bar.com
						//
						// If omitted or empty, the value of the host header is ignored.
						host?: string

						// Method is an extended POSIX regex matched against the method of a
						// request, e.g. "GET", "POST", "PUT", "PATCH", "DELETE", ...
						//
						// If omitted or empty, all methods are allowed.
						method?: string

						// Path is an extended POSIX regex matched against the path of a
						// request. Currently it can contain characters disallowed from the
						// conventional "path" part of a URL as defined by RFC 3986.
						//
						// If omitted or empty, all paths are all allowed.
						path?: string
					}]
				}

				// ServerNames is a list of allowed TLS SNI values. If not empty, then
				// TLS must be present and one of the provided SNIs must be indicated in the
				// TLS handshake.
				serverNames?: [...=~"^([-a-zA-Z0-9_*]+[.]?)+$"]

				// TerminatingTLS is the TLS context for the connection terminated by
				// the L7 proxy. For egress policy this specifies the server-side TLS
				// parameters to be applied on the connections originated from the local
				// endpoint and terminated by the L7 proxy. For ingress policy this specifies
				// the server-side TLS parameters to be applied on the connections
				// originated from a remote source and terminated by the L7 proxy.
				terminatingTLS?: {
					// Certificate is the file name or k8s secret item name for the certificate
					// chain. If omitted, 'tls.crt' is assumed, if it exists. If given, the
					// item must exist.
					certificate?: string

					// PrivateKey is the file name or k8s secret item name for the private key
					// matching the certificate chain. If omitted, 'tls.key' is assumed, if it
					// exists. If given, the item must exist.
					privateKey?: string

					// Secret is the secret that contains the certificates and private key for
					// the TLS context.
					// By default, Cilium will search in this secret for the following items:
					// - 'ca.crt' - Which represents the trusted CA to verify remote source.
					// - 'tls.crt' - Which represents the public key certificate.
					// - 'tls.key' - Which represents the private key matching the public key
					// certificate.
					secret!: {
						// Name is the name of the secret.
						name!: string

						// Namespace is the namespace in which the secret exists. Context of use
						// determines the default value if left out (e.g., "default").
						namespace?: string
					}

					// TrustedCA is the file name or k8s secret item name for the trusted CA.
					// If omitted, 'ca.crt' is assumed, if it exists. If given, the item must
					// exist.
					trustedCA?: string
				}
			}]
		}]

		// IngressDeny is a list of IngressDenyRule which are enforced at ingress.
		// Any rule inserted here will be denied regardless of the allowed ingress
		// rules in the 'ingress' field.
		// If omitted or empty, this rule does not apply at ingress.
		ingressDeny?: [...{
			// FromCIDR is a list of IP blocks which the endpoint subject to the
			// rule is allowed to receive connections from. Only connections which
			// do *not* originate from the cluster or from the local host are subject
			// to CIDR rules. In order to allow in-cluster connectivity, use the
			// FromEndpoints field. This will match on the source IP address of
			// incoming connections. Adding a prefix into FromCIDR or into
			// FromCIDRSet with no ExcludeCIDRs is equivalent. Overlaps are
			// allowed between FromCIDR and FromCIDRSet.
			//
			// Example:
			// Any endpoint with the label "app=my-legacy-pet" is allowed to receive
			// connections from 10.3.9.1
			fromCIDR?: [...string]

			// FromCIDRSet is a list of IP blocks which the endpoint subject to the
			// rule is allowed to receive connections from in addition to FromEndpoints,
			// along with a list of subnets contained within their corresponding IP block
			// from which traffic should not be allowed.
			// This will match on the source IP address of incoming connections. Adding
			// a prefix into FromCIDR or into FromCIDRSet with no ExcludeCIDRs is
			// equivalent. Overlaps are allowed between FromCIDR and FromCIDRSet.
			//
			// Example:
			// Any endpoint with the label "app=my-legacy-pet" is allowed to receive
			// connections from 10.0.0.0/8 except from IPs in subnet 10.96.0.0/12.
			fromCIDRSet?: [...{
				// CIDR is a CIDR prefix / IP Block.
				cidr?: string

				// CIDRGroupRef is a reference to a CiliumCIDRGroup object.
				// A CiliumCIDRGroup contains a list of CIDRs that the endpoint, subject to
				// the rule, can (Ingress/Egress) or cannot (IngressDeny/EgressDeny) receive
				// connections from.
				cidrGroupRef?: =~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"

				// CIDRGroupSelector selects CiliumCIDRGroups by their labels,
				// rather than by name.
				cidrGroupSelector?: {
					// matchExpressions is a list of label selector requirements. The requirements are ANDed.
					matchExpressions?: [...{
						// key is the label key that the selector applies to.
						key!: string

						// operator represents a key's relationship to a set of values.
						// Valid operators are In, NotIn, Exists and DoesNotExist.
						operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

						// values is an array of string values. If the operator is In or NotIn,
						// the values array must be non-empty. If the operator is Exists or DoesNotExist,
						// the values array must be empty. This array is replaced during a strategic
						// merge patch.
						values?: [...string]
					}]

					// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
					// map is equivalent to an element of matchExpressions, whose key field is "key", the
					// operator is "In", and the values array contains only "value". The requirements are ANDed.
					matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
				}

				// ExceptCIDRs is a list of IP blocks which the endpoint subject to the rule
				// is not allowed to initiate connections to. These CIDR prefixes should be
				// contained within Cidr, using ExceptCIDRs together with CIDRGroupRef is not
				// supported yet.
				// These exceptions are only applied to the Cidr in this CIDRRule, and do not
				// apply to any other CIDR prefixes in any other CIDRRules.
				except?: [...string]
			}]

			// FromEndpoints is a list of endpoints identified by an
			// EndpointSelector which are allowed to communicate with the endpoint
			// subject to the rule.
			//
			// Example:
			// Any endpoint with the label "role=backend" can be consumed by any
			// endpoint carrying the label "role=frontend".
			//
			// Note that while an empty non-nil FromEndpoints does not select anything,
			// nil FromEndpoints is implicitly treated as a wildcard selector if ToPorts
			// are also specified.
			// To select everything, use one EndpointSelector without any match requirements.
			fromEndpoints?: [...{
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
			}]

			// FromEntities is a list of special entities which the endpoint subject
			// to the rule is allowed to receive connections from. Supported entities are
			// `world`, `cluster`, `cluster-mesh`, `host`, `remote-node`, `kube-apiserver`, `ingress`, `init`,
			// `health`, `unmanaged`, `none` and `all`.
			fromEntities?: [
				..."all" |
					"world" |
					"cluster" |
					"cluster-mesh" |
					"host" |
					"init" |
					"ingress" |
					"unmanaged" |
					"remote-node" |
					"health" |
					"none" |
					"kube-apiserver",
			]

			// FromGroups allows policies to reference CIDRs provided by external integrations.
			// Currently, only AWS is supported, and the rule can select by multiple sub directives.
			// FromGroups entries are functionally equivalent to FromCIDR, and have the same
			// limitiations. They cannot select traffic originating from within the cluster.
			//
			// Example:
			// fromGroups:
			// - aws:
			// securityGroupsIds:
			// - 'sg-XXXXXXXXXXXXX'
			fromGroups?: [...{
				// AWSGroup is an structure that can be used to whitelisting information from AWS integration
				aws?: {
					// Labels selects AWS ENIs by labels.
					// Multiple labels are AND-ed together.
					labels?: [string]: string

					// Deprecated: Region is unused.
					region?: string

					// SecurityGroupsIds selects VPC SecurityGroups by IDs.
					// If multiple IDs are specified, they are OR-ed together.
					//
					// Note that this may be AND-ed with any Names specified. Specifying both
					// IDs and Names is not recommended.
					securityGroupsIds?: [...string]

					// SecurityGroupsNames selects VPC SecurityGroups by name.
					// If multiple names are specified, they are OR-ed together.
					//
					// Note that this may be AND-ed with any IDs specified. Specifying both
					// IDs and Names is not recommended.
					securityGroupsNames?: [...string]
				}
			}]

			// FromNodes is a list of nodes identified by an
			// EndpointSelector which are allowed to communicate with the endpoint
			// subject to the rule.
			fromNodes?: [...{
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
			}]

			// Deprecated.
			fromRequires?: [...string]

			// ICMPs is a list of ICMP rule identified by type number
			// which the endpoint subject to the rule is not allowed to
			// receive connections on.
			//
			// Example:
			// Any endpoint with the label "app=httpd" can not accept incoming
			// type 8 ICMP connections.
			icmps?: [...{
				// Fields is a list of ICMP fields.
				fields?: [...{
					// Family is a IP address version.
					// Currently, we support `IPv4` and `IPv6`.
					// `IPv4` is set as default.
					family?: "IPv4" | "IPv6"

					// Type is a ICMP-type.
					// It should be an 8bit code (0-255), or it's CamelCase name (for example, "EchoReply").
					// Allowed ICMP types are:
					// Ipv4: EchoReply | DestinationUnreachable | Redirect | Echo | EchoRequest |
					// RouterAdvertisement | RouterSelection | TimeExceeded | ParameterProblem |
					// Timestamp | TimestampReply | Photuris | ExtendedEcho Request | ExtendedEcho Reply
					// Ipv6: DestinationUnreachable | PacketTooBig | TimeExceeded | ParameterProblem |
					// EchoRequest | EchoReply | MulticastListenerQuery| MulticastListenerReport |
					// MulticastListenerDone | RouterSolicitation | RouterAdvertisement | NeighborSolicitation |
					// NeighborAdvertisement | RedirectMessage | RouterRenumbering | ICMPNodeInformationQuery |
					// ICMPNodeInformationResponse | InverseNeighborDiscoverySolicitation |
					// InverseNeighborDiscoveryAdvertisement |
					// HomeAgentAddressDiscoveryRequest | HomeAgentAddressDiscoveryReply | MobilePrefixSolicitation |
					// MobilePrefixAdvertisement | DuplicateAddressRequestCodeSuffix |
					// DuplicateAddressConfirmationCodeSuffix |
					// ExtendedEchoRequest | ExtendedEchoReply
					type!: (int |
						=~"^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]|EchoReply|DestinationUnreachable|Redirect|Echo|RouterAdvertisement|RouterSelection|TimeExceeded|ParameterProblem|Timestamp|TimestampReply|Photuris|ExtendedEchoRequest|ExtendedEcho Reply|PacketTooBig|ParameterProblem|EchoRequest|MulticastListenerQuery|MulticastListenerReport|MulticastListenerDone|RouterSolicitation|RouterAdvertisement|NeighborSolicitation|NeighborAdvertisement|RedirectMessage|RouterRenumbering|ICMPNodeInformationQuery|ICMPNodeInformationResponse|InverseNeighborDiscoverySolicitation|InverseNeighborDiscoveryAdvertisement|HomeAgentAddressDiscoveryRequest|HomeAgentAddressDiscoveryReply|MobilePrefixSolicitation|MobilePrefixAdvertisement|DuplicateAddressRequestCodeSuffix|DuplicateAddressConfirmationCodeSuffix)$")
				}]
			}]

			// ToPorts is a list of destination ports identified by port number and
			// protocol which the endpoint subject to the rule is not allowed to
			// receive connections on.
			//
			// Example:
			// Any endpoint with the label "app=httpd" can not accept incoming
			// connections on port 80/tcp.
			toPorts?: [...{
				// Ports is a list of L4 port/protocol
				ports?: [...{
					// EndPort can only be an L4 port number.
					endPort?: int32 & int & <=65535 & >=0

					// Port can be an L4 port number, or a name in the form of "http"
					// or "http-8080".
					port?:
						=~"^(6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[0-9]{1,4})|([a-zA-Z0-9]-?)*[a-zA-Z](-?[a-zA-Z0-9])*$"

					// Protocol is the L4 protocol. If "ANY", omitted or empty, any protocols
					// with transport ports (TCP, UDP, SCTP) match.
					//
					// Accepted values: "TCP", "UDP", "SCTP", "VRRP", "IGMP", "GRE", "IPIP",
					// "IPV6", "ESP", "AH", "ANY"
					//
					// Tunnel/encapsulation protocols (GRE, IPIP, IPV6, ESP, AH) and other
					// extended IP protocols (VRRP, IGMP) require the --enable-extended-ip-protocols
					// flag to be set. These protocols do not use transport-layer ports.
					//
					// Matching on ICMP is not supported.
					//
					// Named port specified for a container may narrow this down, but may not
					// contradict this.
					protocol?: "TCP" | "UDP" | "SCTP" | "VRRP" | "IGMP" | "GRE" | "IPIP" | "IPV6" | "ESP" | "AH" | "ANY"
				}]
			}]
		}]

		// Labels is a list of optional strings which can be used to
		// re-identify the rule or to store metadata. It is possible to lookup
		// or delete strings based on labels. Labels are not required to be
		// unique, multiple rules can have overlapping or identical labels.
		labels?: [...{
			key!: string

			// Source can be one of the above values (e.g.: LabelSourceK8s).
			source?: string
			value?:  string
		}]

		// Log specifies custom policy-specific Hubble logging configuration.
		log?: {
			// Value is a free-form string that is included in Hubble flows
			// that match this policy. The string is limited to 32 printable characters.
			value?: =~"^\\PC*$"
		}

		// NodeSelector selects all nodes which should be subject to this rule.
		// EndpointSelector and NodeSelector cannot be both empty and are mutually
		// exclusive. Can only be used in CiliumClusterwideNetworkPolicies.
		nodeSelector?: {
			// matchExpressions is a list of label selector requirements. The requirements are ANDed.
			matchExpressions?: [...{
				// key is the label key that the selector applies to.
				key!: string

				// operator represents a key's relationship to a set of values.
				// Valid operators are In, NotIn, Exists and DoesNotExist.
				operator!: "In" | "NotIn" | "Exists" | "DoesNotExist"

				// values is an array of string values. If the operator is In or NotIn,
				// the values array must be non-empty. If the operator is Exists or DoesNotExist,
				// the values array must be empty. This array is replaced during a strategic
				// merge patch.
				values?: [...string]
			}]

			// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
			// map is equivalent to an element of matchExpressions, whose key field is "key", the
			// operator is "In", and the values array contains only "value". The requirements are ANDed.
			matchLabels?: [string]: =~"^(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?$"
		}
	}]

	apiVersion: "cilium.io/v2"
	kind:       "CiliumNetworkPolicy"
	metadata!: {
		name!:      string
		namespace!: string
		labels?: [string]:      string
		annotations?: [string]: string
	}
}
