# 0037 · The tape carries the hour, and its grid is the rule

**Date:** 2026-08-24 · **Item:** HL-003 slice 2 · **Status:** decided
· **Amends:** 0036 §Decision 2

## Context

Slice 2 replaces the tick tape with the identity's ember tape: each contraction a
rounded amber bar rising from a baseline, bar width the duration, the gap between
bars the interval. Decision 0036 set its window to `rule.sustainedWindow` — the hour
— so that decision 0026's honesty (a lull empties the leading edge) would be what the
geometry shows rather than something the copy has to say.

It also told slice 2 to build a graft lifted from a losing design direction: marks at
0:30, 1:00 and 1:30 on the baseline that light as the live mound passes them. Do the
arithmetic on a 370 pt tape spanning an hour and a 60-second contraction is 6 pt wide,
a 5-minute gap 31 pt, and those three marks land 3, 6 and 9 pt apart. They cannot
exist on that axis. The graft was written for a tape whose axis is *this
contraction's elapsed time*; 0036 imported its phrase without checking its scale.

## Decision

1. **The hour wins, and there is no second scale anywhere on the screen.** The tape's
   axis is the trailing `rule.sustainedWindow`, right edge pinned to now. The
   elapsed-duration reading already has the best possible home — slice 1's 84 pt hero
   numeral — and 0036's own rationale is the argument against a second one: two
   renderings of one figure at different scales is how a screen starts contradicting
   itself. **Graft [4] is rejected**, its purpose already served.

2. **The grid is the rule's own interval, not the clock's.** A tick every 5 minutes
   under 5-1-1, every 4 under 4-1-1, every 3 under 3-1-1. This is what makes the tape
   numerate rather than atmospheric, and it does it in the unit the reader was given:
   gaps sitting at or inside **one cell** is decision 0024's frequency share made
   visible, and silence wider than **three cells** is literally 0026 §1's continuity
   break. Both verdict legs become readable off the geometry with no captions at all.
   A 15-minute wall-clock grid would answer a question nobody on this screen is
   asking.

3. **Two mono end caps, and nothing else in words:** `1 H AGO` at the left, `NOW` at
   the right. The baseline and the grid run full width always — they are the axis,
   not data, and an axis that appears only once there is data to put on it is a
   surprise rather than an instrument.

4. **Everything is drawn to true scale, including what is inconvenient.** The live
   mound grows at ~0.1 pt/second and is not exaggerated for drama; the glow may bloom
   past the bar, the bar may not. A young episode right-aligns against now and leaves
   the left of the tape honestly empty — bars march left and exit clipped mid-bar.
   The alternative, an axis that scales with the episode's age, shrinks gaps visually
   while nothing about the pattern has changed: a lying instrument.

5. **Suspect records are drawn to scale and flagged, never excluded** (decision 0032
   §1: flagged on every surface, start still counted for spacing, never auto-deleted).
   A three-minute bar dominates its neighbours because it dominated the hour. Flagged
   as an outline with no fill — texture, not colour, the same discipline the timeline
   already keeps — with the words staying on the timeline row and in History. A slip
   under twenty seconds draws at a 1 pt floor so that it exists at all: a floor of
   visibility, not a lie of magnitude.

6. **The tape replaces `TickTapeGauge` and `GhostTimeline`. `EpisodeTimeline`
   stays.** 0036 said the two displays say the same thing twice; only half of that
   was true. The tick tape's single derived fill was redundant and the ember tape
   shows the raw record it was derived from. The node timeline is the *only* on-screen
   source of per-contraction figures — the newest actual interval and duration rather
   than a mean and a range, the CHECK flag on the screen she is on, and the only
   spoken start-to-start interval in the app. Tape is shape; timeline and columns are
   figures.

7. **The tape speaks a raw count and never a percentage.** `TickTapeGauge` spoke a
   fill percentage, which was a derived figure standing in for evidence. The ember
   tape says "3 contractions in the last hour" — a raw record needs no evidence floor
   — and per-contraction facts stay with the timeline nodes. The
   `SnapshotFactAssertionTests` anchor on `unbroken pattern` moves with the gauge it
   described, re-cut in the same commit per 0036's boundary rule.

## Rationale

The tape earns its space by showing what a derived fill could only assert. Under
0026, sustained evidence is continuity across the hour; on a trailing-window tape with
true positions, continuity is *bars all the way back to the left edge* and a lull is a
growing gap at the leading edge. Nothing computes it, nothing has to be trusted, and
the reader can check the app's claim against the picture — which is the difference
between an instrument and a dashboard.

**Rejected: keeping the duration marks somewhere else on the screen.** Every honest
home for them (a second mini-tape under the numeral) is two contradictory scales three
inches apart. If a 0:30 / 1:00 / 1:30 milestone is ever wanted, its medium is haptic,
not geometric.

**Rejected: tinting bars by whether they meet the rule.** The tape is a raw-record
surface. Verdict legs belong to slice 3's meters, and a tape that colours its own
evidence by its own conclusion is the circularity decisions 0022–0026 were written to
prevent.

## Boundaries

No analysis changes. `PatternAnalysis` gains a pure mapping from records to tape
geometry — normalized positions, widths, flags — which is package-tested like every
other figure on the authoritative path: right-alignment, the clip at the left edge,
one bar and no gap, a suspect at scale, a slip at its floor. Nothing about thresholds,
floors, the latch or the sustained hour moves.
