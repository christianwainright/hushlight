#!/bin/bash
# D1 acceptance gate (spec §8). Run from anywhere.
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0

echo "== Gate 5: hex / fixed-font check =="
# Delegated to the one definition of the rule, which CI calls too — two copies of
# this grep drifted into enforcing two different rules once already.
./scripts/lint-literals.sh || fail=1

echo
echo "== Log audit: breadcrumbs only, no figures (0029 §3) =="
./scripts/lint-logging.sh || fail=1

echo
echo "== HL-006: zero user-facing literals outside a String Catalog =="
./scripts/lint-localizable.sh || fail=1

echo
echo "== HL-049: App Store listing metadata =="
./scripts/lint-store-metadata.sh || fail=1

echo
echo "== HL-055: the rendered review notes match Disclaimers.reviewNotes =="
./scripts/render-review-notes.sh --check || fail=1

echo
echo "== HL-046: catalogs match the compiler's own string extraction =="
./scripts/lint-loc-catalog.sh || fail=1

echo
echo "== HL-033: multi-figure rows take an accessibility-size branch =="
./scripts/lint-row-figures.sh || fail=1

echo
echo "== Font.system(size:) occurrences inside DesignKit (should be Typography.swift only) =="
grep -rn "Font.system(size\|\.system(size" --include="*.swift" Packages/DesignKit | sed 's|^|  |'

echo
echo "== Gate 4: components declaring accessibility =="
missing=""
for f in Packages/DesignKit/Sources/DesignKit/Components/*.swift; do
    if ! grep -q "accessibility" "$f"; then
        missing="$missing\n  $(basename "$f")"
    fi
done
if [ -n "$missing" ]; then
    echo "REVIEW — no accessibility modifiers found in:$(printf "$missing")"
else
    echo "PASS — every component file declares accessibility"
fi

echo
echo "== Preview matrix coverage =="
for f in Packages/DesignKit/Sources/DesignKit/Components/*.swift; do
    if ! grep -q "ComponentMatrix" "$f"; then
        echo "  MISSING ComponentMatrix preview: $(basename "$f")"
        fail=1
    fi
done
echo "  (silence above means all components ship a dark/light × default/XL preview)"

echo
echo "== Build =="
./scripts/build.sh || fail=1

echo
if [ "$fail" -eq 0 ]; then
    echo "D1 GATE: PASS"
else
    echo "D1 GATE: FAIL"
fi
exit "$fail"
