#!/bin/bash
# Runs every package's test suite against the newest installed iOS simulator.
# Packages are tested individually: they are iOS-only, so `swift test` (which targets
# macOS) cannot run them.
set -uo pipefail

# HL-038 removed the Xcode-beta pin: the iOS 18.0 floor builds on any current
# toolchain. Set DEVELOPER_DIR yourself to aim at a specific one.
cd "$(dirname "$0")/.."

# Overridable for CI, whose image may carry a different device set or point release.
DESTINATION="${DESTINATION:-id=$(./scripts/newest-sim.sh)}"

# Every suite by default. Pass package names for a subset. The app target has no
# unit-test bundle; its UI tests run through ./scripts/a11y-ax5.sh and the labor
# QA harness.
ALL_PACKAGES=(DesignKit LaborKit LaborSim)
if [ "$#" -gt 0 ]; then
    PACKAGES=("$@")
else
    PACKAGES=("${ALL_PACKAGES[@]}")
fi
failed=0

for pkg in "${PACKAGES[@]}"; do
    out=$(cd "Packages/$pkg" && xcodebuild test \
        -scheme "$pkg" -destination "$DESTINATION" 2>&1)
    status=$?
    summary=$(echo "$out" | grep -E "Test run with .* tests?" | tail -1)
    if [ "$status" -eq 0 ]; then
        printf '  PASS  %-18s %s\n' "$pkg" "${summary:-no tests}"
    else
        printf '  FAIL  %-18s\n' "$pkg"
        echo "$out" | grep -E "error:|✘|failed" | head -15 | sed 's/^/        /'
        failed=1
    fi
done

if [ "$failed" -eq 0 ]; then
    echo "ALL TESTS PASSED"
else
    echo "TESTS FAILED"
fi
exit "$failed"
