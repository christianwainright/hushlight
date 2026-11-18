#!/bin/bash
# Rubric mutation testing for the labor QA harness (docs/qa/RUBRIC.md §4).
#
# Applies six deliberate one-behavior mutations to the shipping pattern-analysis
# engine (Packages/LaborKit/Sources/LaborKit/PatternAnalysis.swift), one at a time,
# each inside its own scratch git worktree so the real working tree is never
# touched. For every mutation, ./scripts/test.sh LaborSim must FAIL — that is the
# mutant getting KILLED. A mutant that SURVIVES (LaborSim still passes against the
# broken engine) means the rubric has a blind spot: some promise the engine makes
# has no test enforcing it.
#
# LOCAL-ONLY, like scripts/labor-sim.sh: it drives six full worktree checkouts and
# xcodebuild test runs, and takes many minutes. Never wired into scripts/test.sh or
# CI.
#
# Usage:
#   ./scripts/labor-mutate.sh                  # run all six mutations
#   ./scripts/labor-mutate.sh gapWiden          # run just one, by name (for iterating)
set -euo pipefail

cd "$(dirname "$0")/.."

TARGET="Packages/LaborKit/Sources/LaborKit/PatternAnalysis.swift"
if [ ! -f "$TARGET" ]; then
    echo "labor-mutate: $TARGET not found -- run from a checkout that still has LaborKit" >&2
    exit 1
fi

# Re-verified against fix wave D's PatternAnalysis.swift (verdict latch moved onto
# `LaborPattern`): all six pre-images below still match the source verbatim.
#
# `medianNotMean` specifically was re-examined rather than assumed, because decision
# 0024 moved `frequencyMet` off the mean entirely (it now reads a share of in-window
# intervals via integer comparison) -- so the question was whether this mutation
# still targets math anything reads. It does: `.mean` still computes `averageInterval`
# and `averageDuration`, both of which T0-02 compares against `LaborOracle` at every
# probe (RUBRIC §1), and `durationMet` reads `averageDuration` directly (`averageDuration
# >= rule.durationEvidenceThreshold`) -- so a median substitution both breaks oracle
# agreement on two figures across the corpus and can flip a real verdict boolean.
# `frequencyMet` no longer being reachable through this mutation is real, but it isn't
# the only reachable thing, so this stays a mutation of live product math rather than
# a decoration -- kept as-is rather than replaced.
ALL_MUTATIONS=(gapWiden keepSuspect floorTwo windowTwoHours sustainedFromLatest medianNotMean)

SCRATCH=$(mktemp -d)

# Best-effort per-mutation cleanup already removes worktrees as it goes; this is the
# safety net for an interrupted or failed run, so no scratch worktree or temp dir
# outlives the script.
cleanup() {
    local status=$?
    for wt in "$SCRATCH"/*/; do
        [ -d "$wt" ] || continue
        git worktree remove --force "$wt" >/dev/null 2>&1 || true
    done
    git worktree prune >/dev/null 2>&1 || true
    rm -rf "$SCRATCH"
    exit "$status"
}
trap cleanup EXIT

# The exact pre-image and post-image text for each mutation, quoted verbatim from
# PatternAnalysis.swift so the substitution below is a literal string swap, not a
# regex that could drift or over-match. Kept as case statements (not associative
# arrays) for /bin/bash 3.2 compatibility.
mutation_preimage() {
    case "$1" in
        gapWiden) printf '%s' '            if Duration.seconds(gapSeconds) > gap {' ;;
        keepSuspect) printf '%s' '        let usableDurations = inWindow
            .filter { !$0.isSuspect }
            .compactMap(\.duration)' ;;
        floorTwo) printf '%s' '    public static let guidelineEvidenceFloor = 6' ;;
        windowTwoHours) printf '%s' '        let windowStart = now.addingTimeInterval(-rule.sustainedWindow.timeInterval)' ;;
        sustainedFromLatest) printf '%s' '        let patternLength = Duration.seconds(max(0, now.timeIntervalSince(episodeStart)))' ;;
        medianNotMean) printf '%s' '        guard !isEmpty else { return nil }
        let total = reduce(TimeInterval.zero) { $0 + $1.timeInterval }
        return .seconds(total / TimeInterval(count))' ;;
        *) echo "labor-mutate: unknown mutation '$1'" >&2; exit 1 ;;
    esac
}

mutation_postimage() {
    case "$1" in
        gapWiden) printf '%s' '            if Duration.seconds(gapSeconds) >= gap {' ;;
        keepSuspect) printf '%s' '        let usableDurations = inWindow
            .compactMap(\.duration)' ;;
        floorTwo) printf '%s' '    public static let guidelineEvidenceFloor = 2' ;;
        windowTwoHours) printf '%s' '        let windowStart = now.addingTimeInterval(-2 * rule.sustainedWindow.timeInterval)' ;;
        sustainedFromLatest) printf '%s' '        let patternLength = Duration.seconds(max(0, now.timeIntervalSince(latest.startedAt)))' ;;
        medianNotMean) printf '%s' '        guard !isEmpty else { return nil }
        let sortedByDuration = sorted { $0.timeInterval < $1.timeInterval }
        return sortedByDuration[(sortedByDuration.count - 1) / 2]' ;;
        *) echo "labor-mutate: unknown mutation '$1'" >&2; exit 1 ;;
    esac
}

# Applies one mutation's edit to the target file inside a worktree, and fails loudly
# (naming the mutation, exit 1) rather than continuing if anything about the edit
# doesn't hold up. A silently-unapplied mutation would run against the unmodified
# engine, pass, and read as a killed mutant -- hiding a real blind spot instead of
# reporting one.
apply_mutation() {
    local name="$1" worktree="$2"
    local file="$worktree/$TARGET"
    local pre post

    pre=$(mutation_preimage "$name")
    post=$(mutation_postimage "$name")

    # grep -F is line-oriented and two of the six pre-images span three lines, so
    # the existence check is a literal whole-file substring search instead --
    # same "loud, named, exit 1" guarantee, just not tied to grep specifically.
    if ! PRE="$pre" perl -0777 -ne 'exit(index($_, $ENV{PRE}) == -1 ? 1 : 0)' "$file"; then
        echo "labor-mutate: PRE-IMAGE MISSING for mutation '$name' -- expected to find this exact text in $TARGET:" >&2
        echo "$pre" | sed 's/^/    /' >&2
        exit 1
    fi

    PRE="$pre" POST="$post" perl -0777 -pi -e 's/\Q$ENV{PRE}\E/$ENV{POST}/' "$file"

    if git -C "$worktree" diff --quiet -- "$TARGET"; then
        echo "labor-mutate: EDIT DID NOT TAKE for mutation '$name' -- $TARGET is unchanged after substitution" >&2
        exit 1
    fi
}

# Overlays the worktree with the CURRENT working tree's packages and scripts.
#
# A worktree checked out at HEAD carries HEAD's test suite, and the harness that has
# to kill these mutants is routinely uncommitted while it is being written. Without
# this, every mutation would be measured against whatever suite was last committed and
# a blind spot in the new one would read as a clean matrix. Excludes build products
# only -- everything else is copied verbatim, deletions included, so the worktree is
# the working tree plus one mutation and nothing else.
sync_worktree() {
    local worktree="$1"
    rsync -a --delete --exclude '.build' --exclude 'DerivedData' \
        "$PWD/Packages/" "$worktree/Packages/"
    rsync -a --delete "$PWD/scripts/" "$worktree/scripts/"
}

# Best-effort extraction of what actually failed, so the closing matrix says more
# than just KILLED. Falls back gracefully -- this is diagnostic, not load-bearing.
kill_reason() {
    local outfile="$1" line
    # swift-testing first: the LaborSim suite is written against it, and its failure
    # lines name the test directly. XCTest's older shape is kept as a fallback so this
    # keeps working if a suite is ever written the other way.
    line=$(grep -oE "Test [A-Za-z0-9_]+\(.*\) recorded an issue" "$outfile" | head -1)
    if [ -n "$line" ]; then
        echo "${line#Test }" | sed -E 's/ recorded an issue//'
        return
    fi
    line=$(grep -oE "Test Case '-\[[A-Za-z0-9_.]+ [A-Za-z0-9_]+\]' failed" "$outfile" | head -1)
    if [ -n "$line" ]; then
        echo "$line" | sed -E "s/Test Case '-\[[A-Za-z0-9_.]+ ([A-Za-z0-9_]+)\]' failed/\1/"
        return
    fi
    line=$(grep -m1 "error:" "$outfile" || true)
    if [ -n "$line" ]; then
        echo "${line#*error: }" | cut -c1-100
        return
    fi
    echo "test.sh reported failure (see log)"
}

MUTATIONS=("${ALL_MUTATIONS[@]}")
if [ "$#" -gt 0 ]; then
    found=0
    for m in "${ALL_MUTATIONS[@]}"; do
        [ "$m" = "$1" ] && found=1
    done
    if [ "$found" -eq 0 ]; then
        echo "labor-mutate: unknown mutation '$1' -- choose one of: ${ALL_MUTATIONS[*]}" >&2
        exit 1
    fi
    MUTATIONS=("$1")
fi

NAMES=()
STATUSES=()
REASONS=()

for name in "${MUTATIONS[@]}"; do
    worktree="$SCRATCH/$name"
    git worktree add --detach "$worktree" HEAD >/dev/null
    sync_worktree "$worktree"

    apply_mutation "$name" "$worktree"

    outfile="$SCRATCH/$name.log"
    # The failure here is the whole point of the mutation -- guarded so set -e
    # doesn't treat "tests failed" (the good outcome) as a script error.
    if "$worktree/scripts/test.sh" LaborSim > "$outfile" 2>&1; then
        test_status=0
    else
        test_status=$?
    fi

    if [ "$test_status" -ne 0 ] || grep -q "TESTS FAILED" "$outfile"; then
        reason=$(kill_reason "$outfile")
        printf '  KILLED   %-20s %s\n' "$name" "$reason"
        NAMES+=("$name"); STATUSES+=("KILLED"); REASONS+=("$reason")
    else
        printf '  SURVIVED %-20s\n' "$name"
        NAMES+=("$name"); STATUSES+=("SURVIVED"); REASONS+=("n/a")
    fi

    git worktree remove --force "$worktree" >/dev/null 2>&1 || true
done

echo
echo "Mutation matrix:"
printf '  %-20s %-9s %s\n' "MUTATION" "RESULT" "KILLED BY"
printf '  %-20s %-9s %s\n' "--------" "------" "---------"
for i in "${!NAMES[@]}"; do
    printf '  %-20s %-9s %s\n' "${NAMES[$i]}" "${STATUSES[$i]}" "${REASONS[$i]}"
done
echo

any_survived=0
for s in "${STATUSES[@]}"; do
    [ "$s" = "SURVIVED" ] && any_survived=1
done

if [ "$any_survived" -eq 0 ]; then
    echo "MUTATION MATRIX CLEAN"
    exit 0
else
    echo "MUTANTS SURVIVED"
    exit 1
fi
