#!/bin/bash
# The 0029 §3 log audit, in one place. `scripts/gate.sh` and the CI workflow both
# call this script, so the local gate and CI cannot drift into enforcing two
# different rules — the same arrangement as lint-literals.sh.
#
# Two checks. First, shipped code may talk to the unified logger only through
# `Breadcrumb` — one file owns the API whose shape guarantees no user figure can
# be logged (a closed event enum, an error reduced to its type name). Second,
# inside that one file every string interpolation must be one of the approved
# expressions, so a figure cannot sneak in through the file that is allowed to
# log. `BreadcrumbTests` audit the event vocabulary itself.
#
# UITests and `scripts/` are out of scope for the same reason lint-literals.sh
# exempts them: they never enter the app binary.
set -uo pipefail
cd "$(dirname "$0")/.."

breadcrumb="Packages/LaborKit/Sources/LaborKit/Breadcrumb.swift"
fail=0

hits=$(grep -rn "Logger(\|os_log\|NSLog\|print(" --include="*.swift" \
    Hushlight HushlightWidgets Packages/LaborKit/Sources Packages/DesignKit/Sources \
    | grep -v "^$breadcrumb:" || true)

if [ -n "$hits" ]; then
    echo "FAIL — logging outside Breadcrumb.swift (0029 §3):"
    echo "$hits" | sed 's|^|  |'
    fail=1
fi

interpolations=$(grep -n '\\(' "$breadcrumb" | grep -v "rawValue\|errorType" || true)

if [ -n "$interpolations" ]; then
    echo "FAIL — Breadcrumb.swift interpolates something beyond the closed set:"
    echo "$interpolations" | sed 's|^|  |'
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "PASS — logging confined to Breadcrumb.swift; breadcrumbs carry no figures"
fi
exit "$fail"
