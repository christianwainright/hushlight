#!/bin/bash
# HL-046: the String Catalogs must equal what the compiler extracts.
#
# The textual rules in `lint-localizable.sh` run everywhere and cost nothing; this
# one needs Xcode, so it sits with the build in `gate.sh` and on CI's macOS tier.
# What it adds is authority. `SWIFT_EMIT_LOC_STRINGS` makes the compiler emit every
# localizable literal it actually resolved — the thing no textual scan can know —
# and `-exportLocalizations` merges that set into the catalogs. So:
#
#   * a key the code needs and the catalog lacks is ADDED by the export, and
#   * a key the catalog carries that no code path produces is marked `stale`.
#
# Either one means the tree changed, and a changed tree is the failure. Run the
# script, commit what it wrote, translate the new keys — that is the whole loop.
#
# Why this exists at all: the catalogs were `extractionState: manual` with
# extraction switched off, so nothing ever reconciled them. Fifty-three keys were
# missing or near-missed — `%@` where the code passes an integer, a dropped
# leading space, a copy edit the key was never updated for — and every one of them
# fell back to English in nine locales, silently, past three items that each said
# localization was done. A person reading a Spanish screenshot found the first of
# them; this script finds the rest.
#
# The tree is never left modified: the catalogs are snapshotted before the export
# and restored after, so a gate run is read-only whatever it reports.
set -uo pipefail
cd "$(dirname "$0")/.."

CATALOGS=(
    "Hushlight/Localizable.xcstrings"
    "HushlightWidgets/Localizable.xcstrings"
    "Packages/LaborKit/Sources/LaborKit/Resources/Localizable.xcstrings"
)

# No DEVELOPER_DIR of its own: HL-038 removed the Xcode-beta pin from every script
# and decision 0053 dropped the floor to iOS 18, so the machine's `xcode-select`
# is the toolchain. It has to be the same one `build.sh` uses — this gate asserts
# what *that* compiler extracts, and a second toolchain could extract differently.

command -v xcodegen >/dev/null && xcodegen generate >/dev/null 2>&1

tmp="$(mktemp -d)" || { echo "FAIL — could not make a scratch directory" >&2; exit 1; }

# Restoring from the trap, not inline: an interrupt between the export and the
# comparison would otherwise delete the only copy of the catalogs the export just
# rewrote. Everything below this point can be killed safely.
restore() {
    for c in "${CATALOGS[@]}"; do
        [ -f "$tmp/before/$c" ] && cp "$tmp/before/$c" "$c"
    done
    rm -rf "$tmp"
}
trap restore EXIT INT TERM

for c in "${CATALOGS[@]}"; do
    mkdir -p "$tmp/before/$(dirname "$c")" || exit 1
    cp "$c" "$tmp/before/$c" || {
        echo "FAIL — could not snapshot $c; refusing to run an export that rewrites it" >&2
        exit 1
    }
done

if ! xcodebuild -exportLocalizations -project Hushlight.xcodeproj \
        -localizationPath "$tmp/xcloc" -exportLanguage en > "$tmp/log" 2>&1; then
    echo "FAIL — the localization export did not complete:"
    tail -30 "$tmp/log" | sed 's|^|  |'
    exit 1
fi

fail=0
for c in "${CATALOGS[@]}"; do
    if ! diff -q "$tmp/before/$c" "$c" > /dev/null; then
        echo "FAIL — $c is not what the compiler extracts:"
        python3 - "$tmp/before/$c" "$c" << 'PY'
import json, sys
old = json.load(open(sys.argv[1]))["strings"]
new = json.load(open(sys.argv[2]))["strings"]
for k in sorted(set(new) - set(old)):
    print(f"  + missing key, add a translation for it: {k[:100]!r}")
for k in sorted(new):
    if new[k].get("extractionState") == "stale" and old.get(k, {}).get("extractionState") != "stale":
        print(f"  - stale key, no code path produces it: {k[:100]!r}")
for k in sorted(set(old) - set(new)):
    print(f"  ? key dropped by the export: {k[:100]!r}")
PY
        fail=1
    fi
done

if [ "$fail" -ne 0 ]; then
    echo
    echo "  Reproduce and keep the result with:"
    echo "    xcodebuild -exportLocalizations -project Hushlight.xcodeproj \\"
    echo "      -localizationPath \"\$(mktemp -d)\" -exportLanguage en"
    echo "  then translate the new keys through docs/i18n/maps and scripts/apply-language.py."
    exit 1
fi

echo "PASS — the three String Catalogs match the compiler's own extraction"
