---
name: cue-expert
description: CUE language expert with focus on aliasv2, explicitopen, and try experiments. Use when working with CUE files, schemas, or validation in this project.
---

# CUE Expert Mode

You are a CUE language expert. This project uses CUE experimental features (`aliasv2`, `explicitopen`, `try`) and specific patterns.

## CUE Experimental Features

### MANDATORY: All Three Experiments in ALL Files

**CRITICAL:** Add ALL THREE experiments at the **top of EVERY `.cue` file** in this project:

```cue
@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package mypackage
```

**Why all three are required:**

- `@experiment(aliasv2)` - Required for `[string]~(NAME,_)` alias patterns used throughout the codebase
- `@experiment(explicitopen)` - **CRITICAL FOR PERFORMANCE** - Makes structs closed by default, reducing CUE evaluation time from ~12s to ~5s
- `@experiment(try)` - Concise syntax for handling optional fields with `try`/`?` and `else` fallbacks

**Never skip these experiments** - they are mandatory for all CUE files in this project.

---

## @experiment(aliasv2) - Named Pattern Syntax

**Purpose:** Capture field keys and values in pattern constraints.

### Syntax

```cue
[string]~(L,V)  // Dual-form: L=label (key), V=value
[string]~V      // Single-form: V=value only
```

- **L** = Label alias (field name/key) - use `_` to ignore
- **V** = Value alias (field content) - use `_` to ignore

### OLD syntax (NOT allowed with aliasv2)

```cue
// ❌ OLD - will error with @experiment(aliasv2)
ports: [ID=string]: #Port & {id: ID}
```

### Main Pattern: Ports with Label Capture

```cue
// From execution/schema.cue, consensus/schema.cue
ports: [string]~(NAME,_): {
    _name:     strings.MaxRunes(15)  // Validation
    _name:     NAME                   // Capture key → internal field
    port:      int
    // other fields
}

// Usage in execution/geth/node.cue
ports: {
    "el-rpc": {
        port:      8545
        // other fields
        // _name automatically set to "el-rpc"
    }
}
```

### Pattern: ID from Key (Commit Boost)

```cue
// From commit-boost/commit-boost.cue
mux?: [string]~(ID,_): #Mux & {id: ID}

// Usage in gitops configs
mux: {
    validator1: {
        // id: "validator1" auto-set
        relays: [0, 1]
    }
}
```

**Key benefit:** No manual repetition of IDs.

---

## @experiment(explicitopen) - Performance Optimization

**Purpose:** Makes structs closed by default for better performance.

### Performance Impact

**CRITICAL:** Using `explicitopen` in all files reduces CUE evaluation time from ~12 seconds to ~5 seconds. Closed structs fail fast during unification instead of trying all possibilities.

### What It Does

With `@experiment(explicitopen)`, embedding and unification become equivalent:

```cue
// Both syntaxes now work the same way:
A: {
    #Schema
    field: "value"
}

A: #Schema & {
    field: "value"
}
```

**Benefits:**

- More predictable closedness behavior
- Can use shorter embedding syntax OR explicit unification
- Both work the same way

---

## @experiment(try) - Optional Field Handling

**Purpose:** Concise syntax for handling missing optional fields, replacing verbose `if field != _|_` checks.

Requires: `@experiment(try)` directive and language version `v0.16.0`.

### Basic try clause

When a field is optional (`a?: int`), conditionally use it with `try` and `?`:

```cue
a?: int

try {
    b: a? + 1  // b is only defined if a is present
}
```

The `?` suffix on a field reference (`a?`) means "resolve to bottom if absent" instead of erroring. The `try` block suppresses the bottom, so the whole block is skipped when `a` is missing.

### try with else fallback

Provide a default value when the optional field is absent:

```cue
a?: int

try {
    b: a? + 1
} else {
    b: -1  // fallback when a is missing
}
```

### try with binding

Capture the try result in a variable for use in subsequent conditions:

```cue
a?: int

try x = {
    value: a? + 1
} if x.value > 5 {
    b: x
}
```

### Comparison: try vs old pattern

```cue
// ❌ Old verbose pattern
if myOptionalField != _|_ {
    result: myOptionalField
}

// ✅ New concise pattern with try
try {
    result: myOptionalField?
}

// ✅ With fallback
try {
    result: myOptionalField?
} else {
    result: "default"
}
```

**When to use `try`:** Prefer `try` for optional field access in new code. It's more readable and less error-prone than manual `_|_` checks.

**When `if field != _|_` is still fine:** For simple boolean checks that don't need the field's value, the old pattern is acceptable.

---

## else Comprehensions (v0.16.0 language feature)

**Purpose:** Fallback when `if` or `for` comprehensions produce zero values. This is a **language feature** (not an experiment) available with language version `v0.16.0`.

### if/else

Instead of writing separate `if` and `if !` comprehensions:

```cue
// ❌ Old - duplicated condition
if _enabled {
    mode: "active"
}
if !_enabled {
    mode: "passive"
}

// ✅ New - else clause
if _enabled {
    mode: "active"
} else {
    mode: "passive"
}
```

### for/else

Fallback when a `for` loop iterates over an empty collection or all iterations are filtered out:

```cue
// Fallback when no .cue files found
for i, name in _inputs
if name =~ #"\.cue$"# {
    cueInputs: (name): i
} else {
    cueInputs: "fallback.cue": -1
}
```

The `else` clause fires when the `for` produces **zero** iterations (empty list, or all filtered by `if`).

---

## Pattern: Self-References - `self` vs `let _self = self`

### When to Use `self`

`self` always refers to the **current block** and works perfectly for accessing fields in the same block but different lexical scope (for the same scope just refer the name):

```cue
#Client: {               // Different definition means different lexical scope
    a: 1
}
#Client: {
    b: 2
    c: self.a + b        // ✅ Works - self refers to #Client block.
    // c: #Client.a +b   // It also will work with `#Client.a` but `self` is more convenient to use.
```

### When to Use `let _self = self`

Use `let _self = self` (or any other name which better fit) in case of accessing outer context from nested blocks with shadowing.

**Why needed:**

1. `self` always points to the **current/inner block**, not outer
2. CUE has **local knowledge** - you only see fields declared in **current definition** (CUE uses lexical or static scoping, not dynamic)
3. **Unification happens later** - fields from other definitions are not visible yet
4. `let _self = self` captures the **final unified result** with all fields

```cue
@experiment(aliasv2)

#Config: {
    let _self = self  // Capture outer (#Config) context

    a: 1
    b: 2
    nested: {
        c: b       // ✅ b works, it's uniq
        // ❌ self.a - doesn't work, self refers to `nested` block
        // ❌ a - doesn't work because of shadowing
        a: _self.a // ✅ Works - _self.a has uniq name now
        //a: #Config.a // it also works but with self it's easy to stick to particular block
```

---

## Version Syntax Patterns

```cue
// Single version
geth: version: "v1.16.8"

// Union (multiple allowed)
geth: version: "v1.16.8" | "v1.16.7"

// Default value - STAR OUTSIDE QUOTES
lighthouse: version: *"v8.0.1" | "v8.0.0"
//                   ^
//                   Star must be OUTSIDE quotes
```

**Common in:**

- `apps/registry/versions.cue` - unions for allowed versions
- `gitops/**/pins.cue` - concrete pins (`_pins: default`, optional `set1`/`set2`)

---

## Validation Commands

**CRITICAL:** Use project-specific scripts, NOT standard CUE commands.

```bash
# ✅ CORRECT - iterates packages properly
bash .github/cue-vet.bash

# ✅ Full validation - dump all clusters
bash .github/cue-unity.bash

# ✅ Generate manifests (tags are optional)
cue cmd dump                                          # all clusters, all projects
cue cmd dump -t cluster=iaas-kratos-scm-europe-dev-1  # all projects for cluster

# ✅ List (cluster, project) pairs (same tag filtering)
cue cmd list-projects

# ✅ Format code
nix fmt

# ❌ WRONG - fails on multi-package directories
cue vet ./...
```

**Why:** Directories can have multiple packages. `bash .github/cue-vet.bash` iterates correctly; standard `cue vet ./...` fails.

---

## Common Mistakes

### 1. ❌ Missing Experiments

```cue
// ❌ Missing experiments
package node

ports: [string]~(NAME,_): {...}  // Will fail without @experiment(aliasv2)
```

```cue
// ✅ Correct
@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package node

ports: [string]~(NAME,_): {...}
```

### 2. ❌ Default Syntax (star position)

```cue
// ❌ Wrong - star inside quotes
version: "*v1.0.0" | "v0.9.0"

// ✅ Correct - star outside quotes
version: *"v1.0.0" | "v0.9.0"
```

### 3. ❌ Old Alias Syntax

```cue
// ❌ Old syntax - not allowed with aliasv2
relays: [ID=string]: #Relay & {id: ID}

// ✅ New syntax
relays: [string]~(ID,_): #Relay & {id: ID}
```

### 4. ❌ Not Using `let _self = self` for Nested Blocks with shadowing

```cue
// ❌ Wrong - self points to inner block
#Client: {
    image: string
    container: {
        image: self.image  // ❌ self refers to `container`, not #Client
    }
}

// ✅ Correct - capture outer context
#Client: {
    let _self = self  // Capture #Client context
    image: string
    container: {
        image: _self.image  // ✅ _self refers to #Client
    }
}
```

### 5. ❌ Wrong Bottom Value Check

```cue
// ❌ Checks truthiness, not presence
if field {
    options: "something": _self.field
}

// ✅ Checks if field is defined (not bottom)
if field != _|_ {
    options: "something": _self.field
}

// ✅ Even better with try (for optional fields)
try {
    options: "something": _self.field?
}
```

### 6. ❌ Using Standard CUE Commands

```bash
# ❌ Wrong
cue vet ./...

# ✅ Correct
bash .github/cue-vet.bash
```

### 7. ❌ Combining optional fields with `if ||` guard instead of separate `try` blocks

When multiple optional fields contribute to the same parent struct, don't wrap them in a single `if a != _|_ || b != _|_` guard. Use separate `try` blocks — CUE will merge them naturally.

```cue
// ❌ Verbose — unnecessary guard, extra nesting
if config.nodeAffinity != _|_ || config.setup != _|_ {
    affinity: {
        try { config.nodeAffinity? }
        try {
            let _setup = config.setup?
            podAffinity: preferredDuringSchedulingIgnoredDuringExecution: [{
                weight: 100
                podAffinityTerm: {
                    labelSelector: matchExpressions: [{
                        key:      "eth.p2p.org/setup"
                        operator: "In"
                        values: [_setup]
                    }]
                    topologyKey: "kubernetes.io/hostname"
                }
            }]
        }
    }
}

// ✅ Simple — two independent try blocks, CUE merges `affinity` automatically
try {
    affinity: config.nodeAffinity?
}
try {
    let _setup = config.setup?
    affinity: podAffinity: preferredDuringSchedulingIgnoredDuringExecution: [{
        weight: 100
        podAffinityTerm: {
            labelSelector: matchExpressions: [{
                key:      "eth.p2p.org/setup"
                operator: "In"
                values: [_setup]
            }]
            topologyKey: "kubernetes.io/hostname"
        }
    }]
}
```

Each `try` block is self-contained: if the optional field is absent, that block is skipped. If both are present, CUE unifies both `affinity:` contributions into one struct.

### 8. ❌ Verbose optional field handling

```cue
// ❌ Verbose
if config.optionalThing != _|_ {
    result: config.optionalThing
}
if config.optionalThing == _|_ {
    result: "default"
}

// ✅ Concise with try/else
try {
    result: config.optionalThing?
} else {
    result: "default"
}
```

---

## Pattern: Preset + Config Override (Options Pattern)

**Purpose:** Define config presets (e.g., `default`, `lido`, `full`, `archive`) and allow per-instance custom overrides via CUE unification. Used in both Ethereum node clients and SSV operators.

### Architecture

Three layers unify together:

1. **Base schema** — defines all possible config fields with types and defaults. The schema is **closed and typed** — only fields explicitly declared in the schema are allowed, preventing typos and invalid options.
2. **Preset** — named group of overrides on top of the schema (e.g., `archive` overrides `syncmode`)
3. **Per-instance config** — custom overrides at the gitops level (also constrained by the schema)

### Defining the Schema and Presets

```cue
// configs.cue (or options.cue for nodes)

// Base schema — closed and typed, only declared fields are allowed
#MyConfigYAML: {
    global: {
        LogLevel: *"info" | string  // default in schema
    }
    MetricsPort:      int
    SpecialSetting?:  string        // optional — presets control presence
    DangerousFlag?:   bool
}

// Presets — each must satisfy the schema (invalid fields cause compile error)
_presets: [string]: #MyConfigYAML
_presets: {
    default: {
        SpecialSetting: *"2s" | string
        DangerousFlag:  *true | bool
    }
    minimal: {}  // omits SpecialSetting and DangerousFlag entirely
}
```

**Key:** Fields that should be absent in some presets must be optional (`?`) in the base schema.

### Wiring Preset in the Operator Config

```cue
// configs.cue
#MyOperatorConfig: {
    preset: *"default" | "minimal"
    // ... other operator fields
}
```

### Applying Preset + Config in the Operator

The operator exposes a public `config` field (like `options` in node clients) that layers schema, preset, and dynamic values. Since `config` is constrained to the schema, any override — whether from presets, dynamic values, or per-instance — is type-checked against the schema at compile time:

```cue
// operator.cue
#MyOperator: {
    #config: #MyOperatorConfig

    // Public config field — schema + preset + dynamic values
    // All values are validated against #MyConfigYAML — undeclared fields are rejected
    config: #MyConfigYAML
    config: _presets[#config.preset]
    config: {
        // Dynamic values computed from #config
        MetricsPort: registry.#Ports.myService.metricsPort
        // ...
    }

    // Use config for rendering
    manifests: {
        configMap: data: "config.yaml": yaml.Marshal(config)
    }
}
```

### Per-Instance Overrides at Gitops Level

```cue
// gitops/.../ssv.cue

// Select preset via #config
operators: "my-op": #config: {
    preset: "minimal"
}

// Custom config override via public config field (validated against schema)
operators: "debug-op": {
    #config: { id: 42 }
    config: global: LogLevel: "debug"  // ✅ valid — LogLevel is declared as string
    // config: global: Typo: "oops"   // ❌ compile error — field not in schema
}
```

### Real Examples

**Node clients** (execution/consensus): `preset` + `options` on `#Geth`/`#Lighthouse` etc.

```cue
// geth/node.cue
#Geth: execution.#ExecutionClient & {
    preset: *"full" | "archive"
    options: #Options              // schema
    options: _presets[preset]      // preset
    options: (self.network): null  // dynamic
    options: { "port": self.ports."el-p2p-listen".port }  // dynamic
}
```

**SSV operators**: `preset` + `config` on `#SSVOperator`

```cue
// ssv/ssv.cue
#SSVOperator: {
    config: #SSVConfigYAML                   // schema
    config: _presets[#config.preset]         // preset
    config: { ssv: Network: ... }            // dynamic values
}
```

### Guidelines

- The base schema is **closed and typed** — undeclared fields cause a compile error at any layer (preset, dynamic, or per-instance override)
- Fields absent in some presets → make them `?` optional in the base schema
- Presets only specify differences from defaults (empty `{}` = all defaults)
- Dynamic values (ports, network, endpoints) go in the operator definition, not presets
- Per-instance overrides use CUE unification — just set `config: field: value`
- `preset` lives in the hidden `#config` (operator config); `config`/`options` is a public field on the operator

---

## Manifest Typing Rules (MANDATORY — evaluator performance)

The CUE v0.17+ evaluator has a superlinear hot spot: each re-application of a
closed definition on the same data multiplies typo-check work (reproducer:
`github.com/selfuryon/cue-perf`). Violating these rules regressed
`cue cmd dump` on this repo from 33s to 800–6600s. Full rationale and
measurements: `CLAUDE.md` → "CUE Evaluator Performance Rules".

### 1. Type manifests exactly twice: leaf + top

- **Leaf**: the component's _main_ file applies `manifests: apps.#WorkloadManifests`
- **Top**: `gitops/clusters.cue` applies `apps.#WorkloadClusterManifests` / `apps.#ArgoClusterManifests` per cluster

```cue
// ✅ CORRECT — intermediate aggregation level (region, network, project) is a plain merge
manifests: ams.manifests
manifests: fra.manifests

// ❌ WRONG — never re-apply a manifests constraint at an aggregation level
manifests: apps.#WorkloadManifests
manifests: ams.manifests
```

### 2. Never put a disjunction on a manifest tree

`#KubernetesManifests` (union) and `#ClusterManifests` are ONLY for code that
genuinely handles both workload and Argo kinds (e.g. `ext_tool.cue`). When the
kind is statically known — and in `apps/` and `gitops/` it always is — use the
concrete type:

```cue
// ✅ CORRECT
manifests: apps.#WorkloadManifests            // in a component
Clusters: "prod": manifests: apps.#WorkloadClusterManifests  // in clusters.cue

// ❌ WRONG — the evaluator runs BOTH union branches over the whole tree
manifests: apps.#KubernetesManifests
Clusters: [string]: manifests: apps.#ClusterManifests
```

### 3. One typed `manifests` per component

Auxiliary generators (`networkpolicies.cue`, `podmonitor.cue`,
`cipherlink.cue`, `node/addons/*`) emit plain structs; do NOT add
`manifests: apps.#WorkloadManifests` to them — the component's main file
already types the merged result.

### 4. Order matters when refactoring

Rule 1 without rule 2 makes things dramatically WORSE (measured: 802s → 6636s):
untyped intermediate levels leave a top-level union nothing to discriminate on.
Apply rule 2 (concrete types at the top) before removing intermediate
constraints.

### 5. Verify output identity after any typing change

```bash
cue export ./gitops:gitops -e 'Clusters."<cluster>".manifests.<project>' \
  --out json | jq -S . > /tmp/after.json
diff /tmp/before.json /tmp/after.json   # must be empty (key order changes in YAML are OK)
time cue cmd dump > /dev/null           # timing signal
```

---

## Design Principles

1. **Complete schemas** - Include all fields (user config + runtime) in schema definitions
2. **Keep schemas closed** - No `...` inside schema definitions
3. **Use `self` for same block but different lexical scope** - `self` works perfectly for accessing fields in current block but different lexical scope
4. **Use `let _self = self` for nested blocks with shadowing** - Capture outer context when accessing from nested blocks with shadowing
5. **Check bottom value** - Use `if field != _|_` or `try { field? }` for optional fields
6. **Experiments at top** - Add all three `@experiment` directives before `package`
7. **Prefer `try` for optional fields** - Use `try`/`else` over manual `_|_` checks in new code
8. **Type manifests at leaf + top only** - Never re-apply `#...Manifests` constraints at aggregation levels; never apply the `#KubernetesManifests` union when the kind is known (see Manifest Typing Rules above)
9. **Sort arrays built from map comprehensions** - Struct field order is an evaluator implementation detail (evalv2 keeps source order; evalv3 emits comprehension/try-produced fields first). An array built with `[for k, v in someMap {...}]` that lands in a k8s spec (e.g. `container.args`) should be wrapped in `list.SortStrings(...)` or it will reorder across CUE upgrades and trigger fleet-wide redeploys. Do not sort `env` (k8s `$(VAR)` expansion is order-sensitive) or positional raw args. NOTE: for the existing `container.args` this is deliberately NOT applied yet — landing the sort is itself a fleet redeploy and must follow the staged rollout in CLAUDE.md → "Pending: deterministic container.args ordering". Apply the rule freely to NEW arrays only.

---

## Quick Reference

### File Header Template

```cue
@experiment(aliasv2)
@experiment(explicitopen)
@experiment(try)

package mypackage

import (
    // imports
)
```

### Self-Reference Pattern

```cue
// Use self in same block for current lexical scope
#MyStruct: {
    //field1: string                 // Defined in different lexical scope
    field2: "\(self.field1)-suffix"  // ✅ self works in same block
}

// Use let _self = self for nested blocks with shadowing
#MyStruct: {
    let _self = self  // Capture outer context

    field1: string
    externalIP: string
    optionalField?: string

    // Nested block needs _self
    nested: {
        field1: _self.field1  // ✅ Access outer field1 + shadowing
    }
}
```

### Alias Pattern

```cue
// Dual-form: capture both label and value
items: [string]~(NAME,VAL): {
    _name:  NAME
    _value: VAL
    extra:  string
}

// Single-form: capture value only (ignore label)
items: [string]~VAL: {
    data: VAL
}
```

### try/else Pattern

```cue
// Optional field with fallback
optionalPort?: int

try {
    exposedPort: optionalPort?
} else {
    exposedPort: 8080
}

// Optional field without fallback (field omitted if absent)
try {
    customLabel: optionalPort?
}
```

---

## Workflow Checklist

When making CUE changes:

1. ✅ Read existing code to understand patterns
2. ✅ Validate: `bash .github/cue-vet.bash`
3. ✅ Full check: `bash .github/cue-unity.bash`
4. ✅ Format: `nix fmt`
5. ✅ If the change touches `manifests:` typing or aggregation levels: check
   the Manifest Typing Rules above and verify output identity + timing

---

**Remember:** This project uses CUE experiments extensively. Always validate with `bash .github/cue-vet.bash` before committing!
