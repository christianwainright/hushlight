#!/bin/bash
# HL-033 / F-0057 — the reflow lint.
#
# Two S2 defects shipped through a green AX5 leg with the same shape: a view laying
# several data figures across one line, with a `@ScaledMetric` fixed-width column beside
# them, and no accessibility-size branch. At AX5 the columns eat the row and the figures
# break *inside themselves* — `EpisodeTimeline`'s "5:00 apart" wrapped to one character
# per line (F-0055), and `HistoryRow`'s "10:39:29 PM · 1:02 · +5:00" rendered as
# "10:31:0 / 9:29 2 PM" beside "+5:0 / 0" (F-0056).
#
# **Nothing else in this repository can see that.** Apple's accessibility audit
# distinguishes clipped text from reflowed text and reports only the first — a figure
# wrapped to one character per line has every glyph present, in the wrong order, so the
# audit walks it and reports zero. `LayoutInvariantTests` caught F-0055 only indirectly,
# by measuring the hole the collapse left between two nodes, and F-0056 leaves no such
# hole (both the broken and the fixed row are about three lines tall). `pseudo-check.sh`
# applies exactly the right stress — doubled strings — to the timer screen only, at XL
# rather than AX5, and yields screenshots rather than assertions. Both defects were found
# by a person looking at a simulator, which is not a control.
#
# So this is a *shape* check, deliberately crude and deliberately cheap: a file that
# prints two or more `.dataText(.row)` figures and never mentions `isAccessibilitySize`
# is the shape of both defects. It cannot prove a layout reflows — grep does not know
# what an `HStack` is — and it is not trying to. It asks the one question whose answer
# was "no" in both cases: *did anyone think about accessibility sizes in this file at
# all?*
#
# Scope notes:
#   - `.row` only, not `.label` or `.hero`. `.row` is the data-value role, the figures
#     that carry real widths; including the label roles adds false positives and no
#     defect this rule was written from.
#   - Two or more, because one figure on a line cannot be starved by another.
#   - DesignKit is exempt: it defines the roles and has no LaborKit figures to lay out.
#   - Verified against history: this rule fails on `EpisodeTimeline` before HL-031 and on
#     `HistoryScreen` before HL-032, and passes on every other file in the tree — the two
#     real defects and no others.
#
# A view that genuinely needs no branch — figures short enough that no type size can
# starve them — waives itself by saying so in a comment containing
# `isAccessibilitySize`, with the reason. That is the same escape the other lints give,
# and it costs the author one sentence explaining why this row is different from the
# three that were not.
set -uo pipefail
cd "$(dirname "$0")/.."

fails=""
while IFS= read -r file; do
    figures=$(grep -c 'dataText(\.row)' "$file")
    [ "$figures" -ge 2 ] || continue
    grep -q 'isAccessibilitySize' "$file" && continue
    fails="${fails}  ${file}: ${figures} .dataText(.row) figures, no isAccessibilitySize branch"$'\n'
done < <(grep -rl 'dataText(\.row)' --include="*.swift" Hushlight Packages 2>/dev/null \
    | grep -v '/DesignKit/' || true)

if [ -n "$fails" ]; then
    echo "FAIL — views laying out several data figures with no accessibility-size branch:"
    printf '%s' "$fails"
    echo "  At AX5 a fixed column starves the figures beside it and they break inside"
    echo "  themselves — F-0055 and F-0056 both. Stack the row at accessibility sizes"
    echo "  (see LegRowView, EpisodeTimeline, HistoryRow), or waive it in a comment"
    echo "  mentioning isAccessibilitySize and saying why this row cannot starve."
    exit 1
fi

echo "PASS — every multi-figure row takes an accessibility-size branch"
