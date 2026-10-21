#!/usr/bin/env python3
"""Strip matchN validators that `cue get crd` emits and that cost far more
than they check. Run after generating CRDs (see the crd-generation skill);
it is idempotent.

Two forms are removed:

1. `matchN(>=1, [int, string]) & ` in front of `(int | string)` or
   `(int | =~"...")` (x-kubernetes-int-or-string, resource quantities), in
   every file under crd/. The disjunction that follows already allows only
   an int or a string, so the validator is redundant and dropping it changes
   nothing.

2. matchN over schemas that only require fields, such as
   `matchN(1, [{endpointSelector!: _}, {nodeSelector!: _}])` from OpenAPI
   oneOf/anyOf `required` lists, in the files named with --presence. This
   does drop a check, so it is limited to schemas we instantiate in bulk
   (CiliumNetworkPolicy), and the checks we rely on are restated cheaply
   where the type is applied (apps/global.cue, #ScopedTypes).

Why: CUE evaluates matchN by unifying a copy of the whole value with every
schema and validating the result. Cilium's spec carries six such schemas, so
each policy was evaluated six more times over; together with form 1 this
was ~15% of the CPU of a dump. Restore by regenerating the CRDs without this
step once CUE decides these schema shapes without unifying (a patch doing so
exists for internal/core/compile/validator.go, not upstream yet).
"""

import argparse
import pathlib
import re
import sys

INT_OR_STRING = "matchN(>=1, [int, string]) & "
FOLLOWERS = ("(int | string)", '(int | =~"')

PRESENCE = re.compile(r"matchN\((?:>=1|1), \[(?:\{\s*[\w\"-]+!: _\s*\}(?:,\s*)?)+\]\)")


def call_end(src: str, start: int) -> int:
    """Index just past the matchN( ... ) call starting at start."""
    i, depth = src.index("(", start) + 1, 1
    while depth:
        depth += {"(": 1, ")": -1}.get(src[i], 0)
        i += 1
    return i


def strip_int_or_string(src: str) -> tuple[str, int]:
    out, n, i = [], 0, 0
    while (j := src.find(INT_OR_STRING, i)) >= 0:
        rest = src[j + len(INT_OR_STRING):]
        out.append(src[i:j])
        if not rest.startswith(FOLLOWERS):
            sys.exit(f"unexpected form after {INT_OR_STRING!r}: {rest[:60]!r}")
        n += 1
        i = j + len(INT_OR_STRING)
    out.append(src[i:])
    return "".join(out), n


def strip_presence(src: str) -> tuple[str, int]:
    out, n, i = [], 0, 0
    while (j := src.find("matchN(", i)) >= 0:
        end = call_end(src, j)
        call = src[j:end]
        if not PRESENCE.fullmatch(call):
            out.append(src[i:end])
            i = end
            continue
        out.append(src[i:j])
        n += 1
        if src.startswith(" & ", end):
            i = end + len(" & ")  # matchN(...) & {...} -> {...}
        else:
            out.append("_")  # a bare matchN(...) constrains nothing else
            i = end
    out.append(src[i:])
    return "".join(out), n


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("--root", default="crd", help="directory holding generated CRDs")
    p.add_argument("--presence", nargs="*", default=[], help="files to strip presence-only matchN from")
    args = p.parse_args()

    presence = {pathlib.Path(f).resolve() for f in args.presence}
    for path in sorted(pathlib.Path(args.root).rglob("*.cue")):
        src = path.read_text()
        new, n1 = strip_int_or_string(src)
        n2 = 0
        if path.resolve() in presence:
            new, n2 = strip_presence(new)
            presence.discard(path.resolve())
        if new != src:
            path.write_text(new)
            print(f"{path}: {n1} int-or-string, {n2} presence-only matchN removed")
    if presence:
        sys.exit(f"--presence files not under {args.root}: {sorted(map(str, presence))}")


if __name__ == "__main__":
    main()
