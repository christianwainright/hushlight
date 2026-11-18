# 0050 · The stretch answers to the stretch before it

**Date:** 2026-08-26 · **Item:** HL-030 (F-0050) · **Status:** decided
· **Extends:** 0043 (the trend caption tells this hour against the last one)

## Context

F-0050: nothing in the app has any vocabulary for one stretch against another. The
trend caption is scoped to the current episode by design (0043 §5) and the recap
describes a single concluded one, so a woman on the third night of prodromal labor has
no way to ask the question her experience is actually made of — *is tonight different
from last night?* HL-029 established that this is not a copy gap to be closed with a
sentence: it needs a unit, an evidence rule, and a place, which is what this decides.

## Decision

1. **The unit is the stretch, not the night.** `PatternAnalysis.episodes(_:)` already
   splits records on a two-hour gap, and that boundary is what actually separates one
   night's labor from another's. "Night" is a calendar word the data does not support:
   an episode legally spans days — `HistoryScreen` prints per-day markers inside a
   single section for exactly that reason (SP-214) — and "last night" is simply false
   whenever the previous stretch was a morning. The app already says *stretch*
   everywhere else; it keeps saying it here.
2. **One statistic, evaluated twice**, as in 0043 §1: `EpisodeSummary.averageInterval`
   of the live stretch against `EpisodeSummary.averageInterval` of the one before it.
   No new statistic is defined, and no second derivation of an existing one (F-0012).
3. **Both stretches must independently clear the average's own floor** (0043 §2). A
   comparison against a guess is worse than silence, and there is no em dash for an
   absent comparison — an em dash marks a measurement slot below its floor, and this is
   not a measurement slot.
4. **Steady speaks here, where 0043 §3 keeps it silent.** This is the one place the two
   decisions part, and deliberately. The trend caption is unsolicited commentary on a
   pattern the reader is watching unfold, so "the same as an hour ago", printed hourly,
   is the jitter-anxiety this app exists to refuse. This line is the answer to a
   question she came to History carrying — and for the woman on the third night, *"about
   the same as your last stretch"* is not filler, it is the entire answer. It is the
   across-stretch sibling of 0041's rest licence: a fact about measurement that lets her
   stop treating tonight as the night. Silence here is precisely what F-0050 filed.

   The band is the same constant with the opposite consequence: a delta under
   `trendDeltaDenominator` (one-sixth of the reference) reads *about the same* instead
   of reading as nothing at all.
5. **Words and figures, never colour alone** (0043 §4). Three readings — closer
   together, farther apart, about the same — each printing both averages, so the
   sentence can be checked against History's own rows rather than trusted.
6. **Bounded by age, and dated regardless.** A comparison asserts relevance in a way a
   dated record does not: a recap from a previous pregnancy is a record she kept, but a
   *comparison* to it is a claim that it is a reference for tonight, and it is not.
   Seven days — the same window SP-216 already uses for "recently in labor", so the
   codebase has one notion of how long ago still counts. Beyond it, no line. Within it,
   the previous stretch is dated the way HL-026 dates the recap.
7. **It renders on History**, under the current episode's summary band beside the trend
   caption (0043 §5) and only there — never on the timer, which answers "what is
   happening now". The copy names its own scope ("your last stretch") per 0047, because
   there are now three differently-scoped figures on that screen and each has to say
   which one it is.
8. **The oracle moves with it** (SP-194). It already restates `episodes` and `summary`
   independently, so the comparison is refereeable without new primitives.

## Rationale

**Why the interval and not all three legs.** A comparison printing interval, duration
*and* length is a table, and a table asks the reader to work out which row matters. The
question being asked is about spacing — it is the leading leg of the rule, the first
figure the readout prints, and the statistic the trend caption already tracks. One
figure, the one the question is about.

**Why no consequence clause, ever.** "Closer together than your last stretch, so things
are moving" is prognosis, and prognosis is the line 0041 and 0049 both refuse. The
sentence states two measurements and stops. What follows from them is her provider's to
say.

**The risk this carries, stated plainly.** A comparison invites reading progress into
it, and prodromal labor is exactly the case where stretches repeat without progressing.
That risk is the argument *for* shipping it rather than against: the reader is already
making the comparison, from memory, badly, at 3am. Two measured figures and a plain word
are a better instrument than recollection — and the most common honest answer, *about
the same*, is the one that costs her the least.

**Rejected: silence on steady, inherited from 0043 §3.** It would leave the third night
answered exactly as it is answered today, which is not at all.

**Rejected: "night" as the unit.** See §1. It cannot be defined without lying on the
cases that matter most.

## Consequences

- Nothing new is stored. The comparison is derived from records already kept, on device,
  and the privacy ratchet is untouched.
- F-0050 closes.
- History now carries three scoped figures — the episode band, the hour-over-hour trend,
  and this. If a fourth is ever proposed, the screen needs an editor before it needs
  another line.
- Revisit if the seven-day bound proves wrong in either direction: a prodromal stretch
  pattern that spans longer than a week would want a wider one, and a reader comparing
  across an unrelated scare would want a narrower.
