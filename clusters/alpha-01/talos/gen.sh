#!/usr/bin/env bash
# Generates alpha-01 machine config and talosconfig into .secrets/talos/alpha-01
# (or $OUT_DIR).
set -euo pipefail

CLUSTER=alpha-01
# EUI-64 SLAAC address from the Starlink ULA prefix (IPv4 is plain DHCP, no reservations).
NODE=fdc0:ff20:737b:8:7e83:34ff:feb2:d29e
ENDPOINT="https://[${NODE}]:6443"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(git -C "$here" rev-parse --show-toplevel)"
# OUT_DIR lets CI render with throwaway secrets.
out="${OUT_DIR:-$root/.secrets/talos/$CLUSTER}"
mkdir -p "$out"

if [[ ! -f "$out/secrets.yaml" ]]; then
  talosctl gen secrets -o "$out/secrets.yaml"
fi

talosctl gen config "$CLUSTER" "$ENDPOINT" \
  --with-secrets "$out/secrets.yaml" \
  --output-types controlplane,talosconfig \
  --with-docs=false \
  --with-examples=false \
  --config-patch "@$here/patches/kubernetes.yaml" \
  --config-patch "@$here/patches/node.yaml" \
  --config-patch "@$here/patches/network.yaml" \
  --config-patch "@$here/patches/storage.yaml" \
  --output "$out" \
  --force

talosctl --talosconfig "$out/talosconfig" config endpoint "$NODE"
talosctl --talosconfig "$out/talosconfig" config node "$NODE"

talosctl validate --mode metal --strict --config "$out/controlplane.yaml"
