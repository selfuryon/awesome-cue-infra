#!/usr/bin/env python3
"""Lay out the objects that differ between two manifest renders, one file each.

Usage: split-manifests.py <base.yaml> <head.yaml> <base-dir> <head-dir>

manifests-diff diffs <base-dir> against <head-dir>. Rather than writing
every object of both renders and leaving it to `git diff` to find the
changes, both renders are parsed and compared here, and only the objects
that differ — changed, added (head only) or removed (base only) — are
written. An object that is equal on both sides would produce identical
files and no diff, so the result is the same diff for a fraction of the
work: a typical PR changes a few objects of a project.
A render that is missing (a new or a removed project) counts as empty.

Each file is written in a normalized form, so the diff shows what
changed rather than how an encoder wrote it:

- at <namespace>/<kind>/<name>.yaml, the way kubectl spells it
  (`-n <namespace> get <kind>/<name>`); a Namespace goes with its own
  objects (<name>/namespace/<name>.yaml), other cluster-scoped objects
  under _cluster/;
- map keys sorted: key order means nothing to Kubernetes, and it moves
  with CUE upgrades and with how ext_tool.cue marshals;
- strings written the same way on both sides: multi-line ones (ConfigMap
  data) as literal `|` blocks, single-line ones in
  PyYAML's own style. Unlike go-yaml and libyaml's emitter, PyYAML's
  keeps a literal block even when the text holds characters outside the
  BMP (an emoji), so such a ConfigMap is not flattened into
  one quoted line.

Parsing uses libyaml's C loader when PyYAML has it (the PyPI wheels do).

This only shapes the diff; the published artifact is rendered by
publish.yaml and is not affected.
"""

import os
import pathlib
import sys

import yaml

Loader = getattr(yaml, "CSafeLoader", yaml.SafeLoader)


class Dumper(yaml.SafeDumper):
    pass


def str_presenter(dumper, value):
    style = "|" if "\n" in value else None
    return dumper.represent_scalar("tag:yaml.org,2002:str", value, style=style)


Dumper.add_representer(str, str_presenter)


def path_of(doc: dict) -> pathlib.Path:
    meta = doc.get("metadata") or {}
    kind = str(doc.get("kind", "_unknown")).lower()
    name = meta.get("name", "_unnamed")
    # A Namespace sits with the objects it holds; anything else without a
    # namespace (a ClusterRole, a CRD) is cluster-wide.
    namespace = meta.get("namespace") or (name if kind == "namespace" else "_cluster")
    return pathlib.Path(namespace, kind, f"{name}.yaml")


def load(src: str) -> dict:
    if not os.path.exists(src):
        return {}
    with open(src, encoding="utf-8") as f:
        docs = [d for d in yaml.load_all(f, Loader=Loader) if d]
    objects = {}
    for doc in docs:
        path = path_of(doc)
        if path in objects:
            sys.exit(f"{src}: two objects map to {path}")
        objects[path] = doc
    return objects


def write(out: pathlib.Path, path: pathlib.Path, doc: dict) -> None:
    target = out / path
    target.parent.mkdir(parents=True, exist_ok=True)
    with open(target, "w", encoding="utf-8") as f:
        f.write("---\n")
        yaml.dump(doc, f, Dumper=Dumper, sort_keys=True, allow_unicode=True,
                  default_flow_style=False, width=1 << 20)


def main() -> None:
    base_src, head_src = sys.argv[1], sys.argv[2]
    base_out, head_out = pathlib.Path(sys.argv[3]), pathlib.Path(sys.argv[4])
    base_out.mkdir(parents=True, exist_ok=True)
    head_out.mkdir(parents=True, exist_ok=True)
    base, head = load(base_src), load(head_src)
    changed = 0
    for path in sorted(base.keys() | head.keys()):
        b, h = base.get(path), head.get(path)
        if b == h:
            continue
        changed += 1
        if b is not None:
            write(base_out, path, b)
        if h is not None:
            write(head_out, path, h)
    print(f"{len(base)} base and {len(head)} head objects, {changed} differ")


if __name__ == "__main__":
    main()
