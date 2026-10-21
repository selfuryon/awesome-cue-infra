package v1

#DeletingPolicy: {

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
	metadata?: {}

	// DeletingPolicySpec is the specification of the desired behavior of the DeletingPolicy.
	spec!: {
		// Conditions is a list of conditions that must be met for a resource to be deleted.
		// Conditions filter resources that have already been matched by the match constraints,
		// namespaceSelector, and objectSelector. An empty list of conditions matches all resources.
		// There are a maximum of 64 conditions allowed.
		//
		// The exact matching logic is (in order):
		// 1. If ANY condition evaluates to FALSE, the policy is skipped.
		// 2. If ALL conditions evaluate to TRUE, the policy is executed.
		conditions?: [...{
			// Expression represents the expression which will be evaluated by CEL. Must evaluate to bool.
			// CEL expressions have access to the contents of the AdmissionRequest and
			// Authorizer, organized into CEL variables:
			//
			// 'object' - The object from the incoming request. The value is null for DELETE requests.
			// 'oldObject' - The existing object. The value is null for CREATE requests.
			// 'request' - Attributes of the admission request(/pkg/apis/admission/types.go#AdmissionRequest).
			// 'authorizer' - A CEL Authorizer. May be used to perform authorization checks
			// for the principal (user or service account) of the request.
			// See https://pkg.go.dev/k8s.io/apiserver/pkg/cel/library#Authz
			// 'authorizer.requestResource' - A CEL ResourceCheck constructed from the
			// 'authorizer' and configured with the
			// request resource.
			// Documentation on CEL: https://kubernetes.io/docs/reference/using-api/cel/
			//
			// Required.
			expression!: string

			// Name is an identifier for this match condition, used for strategic merging of MatchConditions,
			// as well as providing an identifier for logging purposes. A good name should be descriptive of
			// the associated expression.
			// Name must be a qualified name consisting of alphanumeric characters, '-', '_' or '.', and
			// must start and end with an alphanumeric character (e.g. 'MyName', or 'my.name', or
			// '123-abc', regex used for validation is '([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9]') with an
			// optional DNS subdomain prefix and '/' (e.g. 'example.com/MyName')
			//
			// Required.
			name!: string
		}]

		// DeletionPropagationPolicy defines how resources will be deleted (Foreground, Background, Orphan).
		deletionPropagationPolicy?: "Foreground" | "Background" | "Orphan"

		// MatchConstraints specifies what resources this policy is designed to validate.
		// The AdmissionPolicy cares about a request if it matches _all_ Constraints.
		// Required.
		matchConstraints?: {
			// ExcludeResourceRules describes what operations on what resources/subresources
			// the ValidatingAdmissionPolicy should not care about.
			// The exclude rules take precedence over include rules (if a resource matches both, it is excluded)
			excludeResourceRules?: [...{
				// APIGroups is the API groups the resources belong to. '*' is all groups.
				// If '*' is present, the length of the slice must be one.
				// Required.
				apiGroups?: [...string]

				// APIVersions is the API versions the resources belong to. '*' is all versions.
				// If '*' is present, the length of the slice must be one.
				// Required.
				apiVersions?: [...string]

				// Operations is the operations the admission hook cares about - CREATE, UPDATE,
				// DELETE, CONNECT or *
				// for all of those operations and any future admission operations that are added.
				// If '*' is present, the length of the slice must be one.
				// Required.
				operations?: [...string]

				// ResourceNames is an optional white list of names that the rule applies to. An
				// empty set means that everything is allowed.
				resourceNames?: [...string]

				// Resources is a list of resources this rule applies to.
				//
				// For example:
				// 'pods' means pods.
				// 'pods/log' means the log subresource of pods.
				// '*' means all resources, but not subresources.
				// 'pods/*' means all subresources of pods.
				// '*/scale' means all scale subresources.
				// '*/*' means all resources and their subresources.
				//
				// If wildcard is present, the validation rule will ensure resources do not
				// overlap with each other.
				//
				// Depending on the enclosing object, subresources might not be allowed.
				// Required.
				resources?: [...string]

				// scope specifies the scope of this rule.
				// Valid values are "Cluster", "Namespaced", and "*"
				// "Cluster" means that only cluster-scoped resources will match this rule.
				// Namespace API objects are cluster-scoped.
				// "Namespaced" means that only namespaced resources will match this rule.
				// "*" means that there are no scope restrictions.
				// Subresources match the scope of their parent resource.
				// Default is "*".
				scope?: string
			}]

			// matchPolicy defines how the "MatchResources" list is used to match incoming requests.
			// Allowed values are "Exact" or "Equivalent".
			//
			// - Exact: match a request only if it exactly matches a specified rule.
			// For example, if deployments can be modified via apps/v1, apps/v1beta1, and extensions/v1beta1,
			// but "rules" only included `apiGroups:["apps"], apiVersions:["v1"], resources: ["deployments"]`,
			// a request to apps/v1beta1 or extensions/v1beta1 would not be sent to the
			// ValidatingAdmissionPolicy.
			//
			// - Equivalent: match a request if modifies a resource listed in rules, even
			// via another API group or version.
			// For example, if deployments can be modified via apps/v1, apps/v1beta1, and extensions/v1beta1,
			// and "rules" only included `apiGroups:["apps"], apiVersions:["v1"], resources: ["deployments"]`,
			// a request to apps/v1beta1 or extensions/v1beta1 would be converted to apps/v1
			// and sent to the ValidatingAdmissionPolicy.
			//
			// Defaults to "Equivalent"
			matchPolicy?: string

			// NamespaceSelector decides whether to run the admission control policy on an object based
			// on whether the namespace for that object matches the selector. If the
			// object itself is a namespace, the matching is performed on
			// object.metadata.labels. If the object is another cluster scoped resource,
			// it never skips the policy.
			//
			// For example, to run the webhook on any objects whose namespace is not
			// associated with "runlevel" of "0" or "1"; you will set the selector as
			// follows:
			// "namespaceSelector": {
			// "matchExpressions": [
			// {
			// "key": "runlevel",
			// "operator": "NotIn",
			// "values": [
			// "0",
			// "1"
			// ]
			// }
			// ]
			// }
			//
			// If instead you want to only run the policy on any objects whose
			// namespace is associated with the "environment" of "prod" or "staging";
			// you will set the selector as follows:
			// "namespaceSelector": {
			// "matchExpressions": [
			// {
			// "key": "environment",
			// "operator": "In",
			// "values": [
			// "prod",
			// "staging"
			// ]
			// }
			// ]
			// }
			//
			// See
			// https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
			// for more examples of label selectors.
			//
			// Default to the empty LabelSelector, which matches everything.
			namespaceSelector?: {
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: string

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: string
			}

			// ObjectSelector decides whether to run the validation based on if the
			// object has matching labels. objectSelector is evaluated against both
			// the oldObject and newObject that would be sent to the cel validation, and
			// is considered to match if either object matches the selector. A null
			// object (oldObject in the case of create, or newObject in the case of
			// delete) or an object that cannot have labels (like a
			// DeploymentRollback or a PodProxyOptions object) is not considered to
			// match.
			// Use the object selector only if the webhook is opt-in, because end
			// users may skip the admission webhook by setting the labels.
			// Default to the empty LabelSelector, which matches everything.
			objectSelector?: {
				// matchExpressions is a list of label selector requirements. The requirements are ANDed.
				matchExpressions?: [...{
					// key is the label key that the selector applies to.
					key!: string

					// operator represents a key's relationship to a set of values.
					// Valid operators are In, NotIn, Exists and DoesNotExist.
					operator!: string

					// values is an array of string values. If the operator is In or NotIn,
					// the values array must be non-empty. If the operator is Exists or DoesNotExist,
					// the values array must be empty. This array is replaced during a strategic
					// merge patch.
					values?: [...string]
				}]

				// matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
				// map is equivalent to an element of matchExpressions, whose key field is "key", the
				// operator is "In", and the values array contains only "value". The requirements are ANDed.
				matchLabels?: [string]: string
			}

			// ResourceRules describes what operations on what resources/subresources the
			// ValidatingAdmissionPolicy matches.
			// The policy cares about an operation if it matches _any_ Rule.
			resourceRules?: [...{
				// APIGroups is the API groups the resources belong to. '*' is all groups.
				// If '*' is present, the length of the slice must be one.
				// Required.
				apiGroups?: [...string]

				// APIVersions is the API versions the resources belong to. '*' is all versions.
				// If '*' is present, the length of the slice must be one.
				// Required.
				apiVersions?: [...string]

				// Operations is the operations the admission hook cares about - CREATE, UPDATE,
				// DELETE, CONNECT or *
				// for all of those operations and any future admission operations that are added.
				// If '*' is present, the length of the slice must be one.
				// Required.
				operations?: [...string]

				// ResourceNames is an optional white list of names that the rule applies to. An
				// empty set means that everything is allowed.
				resourceNames?: [...string]

				// Resources is a list of resources this rule applies to.
				//
				// For example:
				// 'pods' means pods.
				// 'pods/log' means the log subresource of pods.
				// '*' means all resources, but not subresources.
				// 'pods/*' means all subresources of pods.
				// '*/scale' means all scale subresources.
				// '*/*' means all resources and their subresources.
				//
				// If wildcard is present, the validation rule will ensure resources do not
				// overlap with each other.
				//
				// Depending on the enclosing object, subresources might not be allowed.
				// Required.
				resources?: [...string]

				// scope specifies the scope of this rule.
				// Valid values are "Cluster", "Namespaced", and "*"
				// "Cluster" means that only cluster-scoped resources will match this rule.
				// Namespace API objects are cluster-scoped.
				// "Namespaced" means that only namespaced resources will match this rule.
				// "*" means that there are no scope restrictions.
				// Subresources match the scope of their parent resource.
				// Default is "*".
				scope?: string
			}]
		}

		// The schedule in Cron format
		// Required.
		schedule!: string

		// Variables contain definitions of variables that can be used in composition of other expressions.
		// Each variable is defined as a named CEL expression.
		// The variables defined here will be available under `variables` in other expressions of the policy
		// except MatchConditions because MatchConditions are evaluated before the rest of the policy.
		//
		// The expression of a variable can refer to other variables defined earlier in
		// the list but not those after.
		// Thus, Variables must be sorted by the order of first appearance and acyclic.
		variables?: [...{
			// Expression is the expression that will be evaluated as the value of the variable.
			// The CEL expression has access to the same identifiers as the CEL expressions in Validation.
			expression!: string

			// Name is the name of the variable. The name must be a valid CEL identifier and
			// unique among all variables.
			// The variable can be accessed in other expressions through `variables`
			// For example, if name is "foo", the variable will be available as `variables.foo`
			name!: string
		}]
	}

	apiVersion: "policies.kyverno.io/v1"
	kind:       "DeletingPolicy"
	metadata!: {
		name!:      string
		namespace?: string
		labels?: [string]:      string
		annotations?: [string]: string
	}
}
