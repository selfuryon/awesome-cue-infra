---
name: cue-expert
description: CUE language expert for this repo — language v0.18.0, postfix aliases and strict embedding, the try experiment, the status of every CUE experiment, scope traps and the v0.18 pitfalls. Use when working with CUE files, schemas, or validation in this project.
---

# CUE Expert Mode

The module is at **language version v0.18.0** (`cue.mod/module.cue`), evaluated with
the CUE release pinned in `nix/overlay.nix` (v0.18.0-rc.1 until a v0.18.0 release
reaches nixpkgs; then the override goes and `flake.lock` picks the version again).
At v0.18.0 postfix aliases (`~(K,V)`, `self`) and strict embedding (`X...`) are
plain language. No experiment is enabled in the repo today.

## CUE experiments

### File header

```cue
package mypackage
```

No attribute by default. Add `@experiment(try)` (before `package`, after
`@extern(embed)` if present) only to a file that uses `try`, `?` selectors, or
`else`/`otherwise` on comprehensions — they fail without it. Never add
`@experiment(aliasv2)` or `@experiment(explicitopen)`: both are stable at v0.18.0 and
the attribute is a no-op that only misleads readers. Generated CRDs under `crd/`
carry no attribute.

### Status of every experiment (CUE v0.18.0-rc.1)

Source of truth: `cue help experiments`, or `internal/cueexperiment/{file,exp}.go` in
the CUE repo. A **per-file** experiment is enabled with `@experiment(name)` and tracks
the module's language version; once **stable** at that version it is always on. A
**global** experiment is set with `CUE_EXPERIMENT=name` (or `name=0` to disable one that
is on by default) and tracks the binary's version.

| per-file                                                                                 | preview | stable | here                          |
| ---------------------------------------------------------------------------------------- | ------- | ------ | ----------------------------- |
| `structcmp` — `==` on all values, unary `==`                                             | v0.14   | v0.15  | always on                     |
| `aliasv2` — postfix aliases `~X` / `~(K,V)`, predeclared `self`; prefix `X=` is rejected | v0.15   | v0.18  | always on (`apps/global.cue`) |
| `explicitopen` — strict embedding, postfix `X...` to open                                | v0.15   | v0.18  | always on                     |
| `try` — `try` clause, `a?` selectors, `else`, `otherwise`                                | v0.16   | —      | not used yet                  |
| `shortcircuit` — `&&` / `\|\|` skip the right operand                                    | v0.17   | —      | not used                      |
| `functions` — `func(...) -> T: body` literals, types, calls                              | v0.18   | —      | not used (preview)            |
| `openlists` — lists open like structs, `#[...]` / `#{...}` closed literals               | v0.18   | —      | do not adopt                  |

| global (`CUE_EXPERIMENT`)                                                                                     | preview | default | stable      | note                                                      |
| ------------------------------------------------------------------------------------------------------------- | ------- | ------- | ----------- | --------------------------------------------------------- |
| `formatv2` — rewritten `cue fmt`                                                                              | v0.18   | v0.18   | —           | alignment differs from older `cue fmt`                    |
| `yamlgoccy` — goccy-based YAML encoder/decoder                                                                | v0.18   | v0.18   | —           | writes non-BMP characters raw, quotes `0X1F`-like strings |
| `openapiv2` — whole-document OpenAPI import/export                                                            | v0.18   | —       | —           | not used                                                  |
| `modules`, `yamlv3decoder`, `decodeint64`, `embed`, `toposort`, `evalv3`, `keepvalidators`, `cmdreferencepkg` | ≤ v0.13 |         | v0.11–v0.16 | stable, cannot be turned off                              |

`@extern(embed)` (file embedding, `_x: _ @embed(file="x.json")`) is still a per-file
attribute and stays where JSON is embedded.

### Upgrading the language version

`cue fix --exp=<name>` migrates files while the module is still **below** the version
where the experiment is stable; afterwards raise `language.version` and drop the now
stable attributes. A file at a version where an experiment is stable cannot opt out.
Every CUE change is checked by comparing renders before/after (see Validation).

### Which preview experiments would help here

- **`try`**: the natural replacement for `if x != _|_ { ... }` guards over optional
  fields. Adopt per file when a component starts using optional config.
- **`functions`**: fits the "function by definition" helpers written as a struct with a
  parameter and an `out` field, called as `(#F & {#c: x}).out` — e.g. `#FluxChart`,
  `#ArgoChart` in `apps/render.cue`. Semantics still change between previews: wait until
  it is stable. Component definitions (`#X: {#cluster, #version, component: ...}`) are
  templates, not functions: keep them as unification.
- **`shortcircuit`**: turn on in a file only when a condition like
  `a != _|_ && a.b == 1` is wanted; it changes the meaning of conditions whose right
  side carries an error.
- **`openlists`**: gives nothing (no list relies on being closed) and removes the
  length check that catches a mis-merged list.

---

## Postfix aliases and `self` (stable at v0.18)

```cue
[string]~(L,V)  // L = label (key), V = value; `_` ignores one
[string]~V      // value only (also written ~(V))
```

The manifest types use them to default `metadata.name` from the key and to push the
namespace down from the scope key (`apps/global.cue`):

```cue
#ScopedTypes: [string]~(TYPE,_): [string]~(ID,_): {
	kind:     *strings.ToTitle(TYPE) | string
	metadata: name: *ID | string
}

#Manifests: {
	scoped: [string]~(ns,_): [string]~(type,_): [string]~(name,_): {
		metadata: namespace: ns
	}
}
```

The old prefix form is a parse error at language v0.18:

```cue
ports: [ID=string]: #Port & {id: ID}        // ❌
ports: [string]~(ID,_): #Port & {id: ID}    // ✅
```

## Strict embedding and `X...` (stable at v0.18)

Embedding a closed value closes the embedding struct to that value's fields, exactly
as unifying with it does; `X...` opens a closed value on purpose:

```cue
A: {#Schema, field: "value"}    // same as #Schema & {field: "value"}
B: #Schema... & {extra: 1}      // explicitly opened
```

---

## v0.18 pitfalls

Constructs older CUE accepted that fail at v0.18 (seen in etherno-infra; none occur
here, do not introduce them):

1. **Selecting a struct out of a definition and adding a field to it.**
   `_cfg.storage? & {extra: true}` with `_cfg = #config` fails `field not allowed`:
   what a reference selects from a definition stays closed. Spell the fields out.
2. **A `let` inside a definition field that selects regular data** treats that data as
   closed and rejects fields added elsewhere. Declare the `let` on the enclosing struct,
   outside the definition.
3. **A `try` nested in another `try` that dereferences an absent optional field**
   reports `cyclic reference` (cue-lang/cue#4486). Use an `if x != _|_` guard for the
   inner one.

1 and 2 fail `cue vet`; 3 is lazy (vet passes, `cue cmd dump`/`yaml.Marshal` hits it),
so check CUE changes with both. The v0.18 YAML encoder writes non-BMP characters raw
and may quote strings differently: compare renders as objects, not bytes.

---

## Scope traps in this repo

### Self-reference inside a unification literal

```cue
// ❌ the right-hand #cluster is the inner field itself (top), not the outer one
(base_x.#X & {#cluster: #cluster}).component

// ✅ bind the outer value first
let _c = #cluster
(app_x.#X & {#cluster: _c}).component
```

Same for `#pins: #pins`, `#components: #components`, `#versions: {a: #versions.a}`.

### Fields of a definition are not in lexical scope of a literal unified with it

```cue
#Core: #Cluster & {
	config:   _        // ✅ declare to bring #Cluster's fields into scope
	versions: _
	components: cilium: (app_cilium.#Cilium & {#cluster: config, #version: versions.cilium}).component
}
```

Without the declarations: `reference "config" not found`.

### Field names shadow imports

A field `cilium:` hides an import `cilium` inside its struct: alias component imports
(`app_cilium "…/apps/network/cilium"`).

### `self` vs `let _self = self`

`self` is the current block. From a nested block that shadows a name, capture the outer
one: `let _self = self` at the outer level, then `_self.image` inside.

### Undefined fields in comparisons

`_current[n] != _source[n]` with `_current[n]` absent is an error, not false. Guard
with `_current[n] != _|_` first, in a separate `if` clause (or use `try` + `?`).

### Struct field order is not a contract

`json.Marshal`/`yaml.Marshal` emit fields in the evaluator's order, which can differ from
source order (comprehension-produced fields move). When order matters in output (e.g.
`pins.json` written by `cue cmd promote`), build an ordered list and render it by hand.
Arrays built from map comprehensions that land in specs (args) should be sorted; never
sort `env` (`$(VAR)` expansion is order-sensitive).

---

## `try` / `else` / `otherwise` (preview, `@experiment(try)`)

```cue
a?: int

try {
	b: a? + 1          // only when a is present
} else {
	b: -1              // fallback
}

try x = {value: a? + 1} if x.value > 5 {
	big: x
}

if _enabled {mode: "active"} else {mode: "passive"}

for i, name in _inputs if name =~ #"\.cue$"# {
	cueInputs: (name): i
} otherwise {
	cueInputs: "fallback.cue": -1   // when the comprehension yields nothing
}
```

`else` follows an `if`/`try` clause; a comprehension with a `for` (or several clauses)
takes `otherwise` (`fallback` in v0.16, rewritten by `cue fmt`). Without the attribute
the file fails with "else requires @experiment(try)".

---

## Manifest typing (evaluator performance)

Re-applying a closed definition on the same data multiplies typo-check work
(reproducer: `github.com/selfuryon/cue-perf`), so:

- Apply `#Manifests` where a tree is produced (`#Render.out`, `#Release`, a component's
  `manifests`) and at the registry (`clusters.cue` `#Entry`) — not again at
  intermediate levels.
- Never type a manifest tree with a disjunction; the evaluator runs every branch over
  the whole tree.
- Prefer marshalling each object (`yaml.Marshal(object)`) over collecting objects into a
  list: a list comprehension body is a struct literal that CUE never structure-shares,
  so `[for o in objects {o}]` evaluates every object again (see `#Objects` in
  `ext_tool.cue`).

---

## Validation

```bash
bash .github/cue-vet.bash                                # every package (not `cue vet ./...`)
cue cmd dump -t cluster=alpha-01 -t project=system       # render a project
cue cmd write-release                                    # release layer must stay in sync
nix fmt                                                  # cue fmt (formatv2) via treefmt
```

Verify a refactor or a CUE upgrade by rendering every (cluster, project) before and
after and comparing as objects, e.g.:

```bash
for c in alpha-01 beta-01; do for p in bootstrap system apps; do
  cue cmd dump -t cluster=$c -t project=$p > /tmp/after-$c-$p.yaml
done; done
python3 .github/split-manifests.py /tmp/before-alpha-01-system.yaml /tmp/after-alpha-01-system.yaml /tmp/b /tmp/h
# "... 0 differ" means the same objects
```

## Common mistakes

- Star inside quotes: `"*v1" | "v2"` ❌ → `*"v1" | "v2"` ✅.
- `if field {` checks truthiness; presence is `if field != _|_ {` (or `try {… field? …}`).
- Values a cluster must be able to override are defaults in the component
  (`replicas: *1 | int`), otherwise the override conflicts.
- Unification cannot remove a component or a field: start from the smaller definition
  (`#Core`) and add.
