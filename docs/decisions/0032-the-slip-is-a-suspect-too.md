# 0032 — The slip is a suspect too

**Status:** accepted (SP-203, from the A1.2 walkthrough: a double tap recorded an
11-second "contraction" and the app said nothing)
**Date:** 2026-08-23

## Context

`Contraction.isSuspect` has always been one-sided. A record over three minutes is
treated as a forgotten stop-tap: flagged `CHECK · OVER 3 MIN` in History and on the
timeline, excluded from the duration mean, its start still counted for spacing, and
never auto-deleted. Nothing looked at the other end.

The walkthrough's mis-tap is the other end. An 11-second record enters the exact
average `durationMet` reads, and it drags it down — the same distortion the long
side is already protected against, in the direction that *suppresses* a verdict
rather than inventing one. The QA corpus has been generating this failure all
along: `pPhantom` drops a 2–10 s start/stop pair into dead time on 0.5–8 % of
contractions by profile, and every one of them has been averaged in as a real
contraction.

There is a second asymmetry underneath, and it is the reason this needs a decision
rather than a symmetric one-liner. Decision 0023 §2 relieves the usable-duration
floor by one when a suspect sits in the window, because *a forgotten stop-tap is
itself evidence that a contraction happened and ran long*. That reasoning does not
transfer. A slip is evidence of nothing.

## Decisions

1. **The suspect predicate gains a short side: a completed record under 20 s is a
   slip.** `Contraction.suspicion` now returns `.tooLong`, `.tooShort` or nil, and
   `isSuspect` is `suspicion != nil`. Both bounds are strict: 180 s exactly and 20 s
   exactly are believable recordings. Treatment is symmetric with the long side —
   flagged on every surface, excluded from duration means (window and episode
   summary alike), start still counted for spacing, never auto-deleted.

   *Calibration evidence,* measured on corpus 2.0.0's 413 scenarios, engine leg:

   | slip floor | suppressions (S4) | false-met scenarios (S2) |
   |---|---|---|
   | none (before) | 46 | 40 |
   | 15 s | 42 | 42 |
   | **20 s** | **41** | **42** |

   Twenty seconds recovers five suppressed labors for two more alarms, and buys the
   fifth over fifteen seconds at no additional alarm cost. That is the trade decision
   0021 §2's ranking law asks for: S4 above S2, *a verdict that fires early is alarm;
   one that fires late is worse.* T0 stayed 413/413 clean across the change — the app
   and the independent oracle moved together, which is the only reason the numbers
   above mean anything.

2. **Only the long side relieves the duration floor.** Decision 0023 §2's relief is
   scoped to `.tooLong`. A slip must not lower the evidence bar for the verdict it is
   noise in.

3. **One number, three surfaces.** The timer's slip strip offers to delete at exactly
   `Contraction.slipDuration`, History and the timeline flag at it, and the duration
   mean excludes at it. The alternative — a generous prompt over a tighter silent
   exclusion — would let the same record be called a likely slip on one screen and
   averaged in on another.

4. **The correction is offered at the button, never taken automatically.** After an
   end-tap under the floor, a transient strip above the disc reads
   "Recorded 0:11 — likely a slip." with a Delete. It is not an alert, it blocks
   nothing, and it grows the bottom bar *upward* so the disc never moves under a
   thumb. It self-dismisses after ten seconds — except under VoiceOver, where a strip
   that vanishes on a timer is one she may never reach, so it waits for the next tap.
   Deleting is undoable from History like any other delete.

5. **The flag says which mistake it is.** `CHECK · UNDER 20 S` beside
   `CHECK · OVER 3 MIN`, from one vocabulary in `LaborFormat`, spoken as "under
   twenty seconds — likely a slip, check this one". The two mistakes call for
   different things from a reader; a single word for both would hide that.

## Boundaries

Interval math is untouched: a slip's *start* is a real tap at a real time and still
spaces the pattern, exactly as a forgotten stop-tap's does. Nothing is deleted by the
app. Displayed durations remain exact — a slip prints `0:11`, never rounded or
hidden. The three rule thresholds, the 50 s duration allowance, the latch and the
sustained hour are all unchanged.

The App Review notes (`Disclaimers.reviewNotes`) describe the app's behavior and
therefore move with it, in the same commit.

## Alternatives rejected

- **Flag but do not exclude.** Keeps the mean "honest" in the sense of using every
  record, and leaves the F-0023 harm in place: 46 suppressed labors, five of them
  attributable to junk the app itself already suspects. The mean's purpose is to
  describe contractions; a record the app is willing to label a slip is not one.
- **Exclude but do not flag.** Silent arithmetic on the safety path. The long side
  was never allowed to work this way and neither is this one.
- **A tighter floor (15 s) for the exclusion, 20 s for the prompt.** Measured one
  suppression worse, and it splits the definition of "slip" across two numbers that
  would eventually disagree in front of a reader.
- **Auto-delete the slip.** The app does not delete a woman's record of her own
  night, in either direction, for any reason.
