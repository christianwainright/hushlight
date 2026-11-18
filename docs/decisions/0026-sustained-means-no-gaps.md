# 0026 — Sustained means no gaps

**Status:** accepted (findings F-0010, F-0022 — sustainedMet ripens through a
50-minute lull; the tick tape asserts it)
**Date:** 2026-08-16

## Context

`sustainedMet` asks whether `now − episodeStart ≥ 1 h`. Six quick contractions, a
50-minute silence, one more tap — and "sustained for an hour" is true, with the
tick tape (whose fill is exactly this quantity) rendering a full bar as the visual
proof. Elapsed time is not a sustained pattern; the dimension exists to
distinguish an hour of labor from an hour that merely contains some.

## Decisions

1. **Sustained requires continuity: `patternLength ≥ 1 h` AND no start-to-start
   gap inside the trailing hour exceeds 3× the rule's interval threshold**
   (5-1-1 → 15 min; 4-1-1 → 12 min; 3-1-1 → 9 min). Triple the expected spacing is
   a break, not jitter — a pattern "every ≤5 minutes" with a 20-minute hole in it
   is not that pattern. The multiplier scales with the rule the provider chose,
   the same way the rule itself does.
2. **The tick tape renders sustained *evidence*, not elapsed time:** fill = time
   since the last continuity break (or episode start, whichever is later), capped
   at the hour. A lull visibly resets the tape — the instrument now shows the
   dimension it implies. 0022.6's interim yield-on-saturation is superseded: a
   tape that reflects continuity re-earns its place and empties honestly when the
   pattern breaks.
3. `patternLength` itself (the PATTERN figure, "how long has this been happening")
   keeps its episode anchor — it answers a different question and is dated by
   0022. Only the verdict dimension and the tape change meaning.

## Boundaries

Both sides of the new boundary get unit tests (a 14:59 in-window gap sustains
under 5-1-1; 15:01 breaks). The oracle mirrors the definition. The W4 detection
scenario flips to a regression pin: burst-lull-tap must now read unmet on the
sustained dimension.

## Alternatives rejected

- **Windowed count as a proxy (≥N in the hour).** Already exists as the evidence
  floor; conflating floor and continuity would double-count one signal and still
  pass a front-loaded burst.
- **Fixed gap cap (e.g. always 15 min).** A 15-minute hole is jitter at 5-1-1 and
  five missed cycles at 3-1-1; the cap must scale with the promised cadence.
- **Anchoring patternLength at the latest start.** Kills the honest "since 9:12 PM"
  answer and was mutation-tested as breaking the whole-episode figures (the
  `sustainedFromLatest` mutant died broadly for good reason).
