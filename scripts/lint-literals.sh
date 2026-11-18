#!/bin/bash
# The DESIGN-SPEC §8 literal ban, in one place.
#
# Raw hex, `Color(red:)` and `Font.system(size:)` are banned in shipped app code
# outside DesignKit (CLAUDE.md § Conventions). This script is the single definition
# of that rule: `scripts/gate.sh` and the CI workflow both call it, so the local
# gate and CI cannot drift into enforcing two different rules.
#
# `scripts/` is exempt because it is build tooling, not shipped code — the icon
# generator draws with CoreGraphics and cannot import DesignKit. Nothing under
# `scripts/` ends up in an app binary.
set -uo pipefail
cd "$(dirname "$0")/.."

hits=$(grep -rn "Color(red\|#colorLiteral\|Font.system(size" \
    --include="*.swift" . \
    | grep -v DesignKit \
    | grep -v "^\./scripts/" \
    | grep -v "^\./\.claude/" || true)

if [ -n "$hits" ]; then
    echo "FAIL — banned literals outside DesignKit:"
    echo "$hits" | sed 's|^|  |'
    exit 1
fi

echo "PASS — no banned literals outside DesignKit"
