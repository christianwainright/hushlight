#!/bin/bash
# HL-058c: frame the iPad captures — English from spec-ipad.json into frames-ipad/, each
# language from spec-ipad/<lang>.json into frames-ipad/<lang>/. The framer writes into a
# scratch directory (its layout is frames/ + preview/, and an iPad spec has no preview),
# and this copies the two PNGs where the push script reads them.
#
#   ./scripts/make-store-frames-ipad.sh          # all nine
set -euo pipefail
cd "$(dirname "$0")/.."
STORE=docs/design/hushlight/store

frame() {
    local spec=$1 out=$2
    local scratch; scratch=$(mktemp -d -t store-ipad-frames)
    swift scripts/make-store-frames.swift "$spec" "$scratch" >/dev/null
    mkdir -p "$out"
    cp "$scratch"/frames/pad-*.png "$out"/
    echo "make-store-frames-ipad: $out/ ($(ls "$out" | wc -l | tr -d ' ') frames)"
}

frame "$STORE/spec-ipad.json" "$STORE/frames-ipad"
for spec in "$STORE"/spec-ipad/*.json; do
    lang=$(basename "$spec" .json)
    [ -f "$STORE/raw-ipad/$lang/pad-hand.png" ] || { echo "make-store-frames-ipad: no raw-ipad/$lang yet, skipping"; continue; }
    frame "$spec" "$STORE/frames-ipad/$lang"
done
