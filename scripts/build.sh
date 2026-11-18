#!/bin/bash
# Builds the app against the newest installed iOS simulator.
#
# HL-038 removed the Xcode-beta pin that used to live here. It existed for exactly
# one reason — the old iOS 27.0 deployment target, which no shipping SDK could
# satisfy — and the floor is now iOS 18.0, which every current Xcode builds. Set
# DEVELOPER_DIR yourself to aim at a specific toolchain; the machine's xcode-select
# is the default because a released app should build on a released toolchain.
set -euo pipefail

cd "$(dirname "$0")/.."

# Overridable for CI, whose image may carry a different device set or point release.
DESTINATION="${DESTINATION:-id=$(./scripts/newest-sim.sh)}"

# Regenerate when missing — a fresh worktree — or when stale. The project is
# gitignored, so a pull that adds an app-target file leaves an existing worktree's
# project silently blind to it, and the failure that produces names a missing type
# instead of the stale project that cannot see it (HL-020; it fired exactly that way
# on the first post-merge build after PR #1). Staleness means: project.yml or any
# file under an app-target source directory is newer than the generated pbxproj.
# `-newer` stops on the first hit and a warm build finds nothing. The deliberate
# trade: editing an *existing* file also trips it, so an edit-then-build pays one
# ~1s regenerate before the pbxproj is newest again — accepted, because telling a
# new file from an edited one costs more machinery than the second it saves, and a
# regenerate is always safe where staleness never is. Package sources are out of
# scope — SPM globs them itself.
if [ ! -d Hushlight.xcodeproj ]; then
    xcodegen generate
elif [ -n "$(find project.yml Hushlight HushlightWidgets HushlightUITests \
        -newer Hushlight.xcodeproj/project.pbxproj -print -quit 2>/dev/null)" ]; then
    echo "build.sh: generated project is stale — regenerating (HL-020)"
    xcodegen generate
fi

# One app, one scheme. The argument form survives for CI symmetry.
if [ "$#" -gt 0 ]; then
    SCHEMES=("$@")
else
    SCHEMES=(Hushlight)
fi

failed=0
for scheme in "${SCHEMES[@]}"; do
    set +e
    xcodebuild -project Hushlight.xcodeproj \
        -scheme "$scheme" \
        -destination "$DESTINATION" \
        -quiet \
        build 2>&1 | grep -Ev '^$' | tail -40
    status=${PIPESTATUS[0]}
    set -e
    if [ "$status" -eq 0 ]; then
        echo "BUILD SUCCEEDED ($scheme)"
    else
        echo "BUILD FAILED ($scheme, exit $status)"
        failed=1
    fi
done
exit "$failed"
