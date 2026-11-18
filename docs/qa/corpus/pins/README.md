# Regression pins

One frozen scenario JSON per fixed finding (`F-nnnn.json`), additive-only — the
harness's own regression suite. A pin is the exact manifest that caught the finding,
plus its expected post-fix results. Never regenerate a pin from seeds; the point is
that it cannot drift.

**The canonical pins live in the package**, at
`Packages/LaborSim/Tests/LaborSimTests/Fixtures/Pins/`, so `PinTests` replays them on
every run and CI enforces them. This directory is the human index: what each pin is,
and what it proves.

Why the split. A pin has to run to be worth anything, and a fixture that only a person
reads is a fixture that rots. But the register (`docs/qa/FINDINGS.md`) reasons about
findings, not about bundle resources, so it needs somewhere to point that explains the
pin rather than encoding it.

## The index

| Pin | Finding | Scenario | What it proves |
|---|---|---|---|
| `F-0001.json` | F-0001 · S3 · bug | `boundaryBattery-advRestoreWhileRunning` | Start A, delete A mid-run, start B, undo. A comes back **closed at its own start**; B stays the record the next stop tap finds. Both rows survive; at most one is ever open. |
| `F-0002.json` | F-0002 · S3 · bug | `classicNullipara-v0-clockHostile-r0-fiveOneOne` | A backward device-clock set stamps a start earlier than an already-completed record. `isRunning` and `runningSince` give one answer at every action of the scenario. |
| `F-0003.json` | F-0003 · S4 · bug | `classicNullipara-v0-chaotic-r0-fiveOneOne` | In that state the stop tap **ends** the running contraction instead of no-opping into a new start. The model's timeline tracks the fold row for row for the rest of the labor — F-0003 lost up to half of it. |
| `F-0004.json` | F-0004 · S3 · design-gap | `multiDayLatent-v0-exhaustedSolo-r0-fiveOneOne` | At two hours and a minute past the newest start: an open record keeps the episode live (decision 0022 §1), and a finished one goes stale **with a last-ended time to date the returning copy from** (§2). Never onboarding copy over a live timer. |
| `F-0007.json` | F-0007 · S4 · design-gap | `weakness-w6-one-suspect` (W6) | Six in the window, three usable durations, then one forgotten stop-tap turns a fourth suspect. The duration mean survives on the relieved floor (decision 0023 §2) and the verdict stays — a forgotten stop is evidence a contraction happened, not grounds to withdraw the two dimensions that had nothing to do with duration. |
| `F-0008.json` | F-0008 · S2 · design-gap | `weakness-w2-plain-coupling` (W2, textbook form) | Coupled back labor recorded faithfully — gaps alternating two and eight minutes. The windowed **mean** still sits under the threshold; the share (decision 0024) reads seven of thirteen and refuses. `intervalRange` prints 2:00–8:00, the spread the mean was hiding. |
| `F-0009.json` | F-0009 · S2 · design-gap | `weakness-w1-flapping` (W1) | Alternating 270/330 spacing, whose mean drifted across the 300 s line as intervals aged out. The **presented** verdict never retracts at any probe of the grid (decisions 0024 and 0025). |
| `F-0035.json` | F-0035 · S4 · design-gap | `slip-among-good-fiveOneOne` (hand-authored) | Twelve believable 52 s contractions five minutes apart, an hour and eleven minutes in, plus one 11 s double tap in the dead time between two of them. The slip is flagged and out of the duration mean, so the mean reads 0:52 and the verdict stands — averaged in it reads 48 s, under decision 0023's threshold, and the whole verdict goes quiet. Its start still splits one gap in two and frequency still passes. The mirror of F-0007. |
| `F-0010.json` | F-0010 · S2 · design-gap | `weakness-w4-lull` (W4) | Thirty contractions ninety seconds apart, a forty-three-minute silence, one more tap. `patternLength` still clears the hour; `sustainedMet` is false and `sustainedEvidence` is zero (decision 0026) — the tape starts over instead of asserting the lull away. |

Every pin additionally carries the invariants `PinTests` asserts over all of them:
never two open records, both container legs replaying clean and agreeing with the
fold, the engine still agreeing with `LaborOracle`, and no negative figure at any
probe (F-0011).

## Minting a new pin

Once per finding, at the moment it is fixed:

1. Identify the catching scenario from the finding's own `KnownFindings` entry — its
   `scenarioIdPattern` is the record of what caught it. Where the pattern is a glob,
   take the first match in the leg's own pool (`ScenarioCorpus.standard` for the pure
   leg, `ReplaySubsample.refs` for the container legs), which is deterministic.
2. Encode `ScenarioCorpus.generate(ref)` through `CanonicalJSON.data(_:pretty: true)`
   and write it to `Fixtures/Pins/F-nnnn.json`. The simulator test process can write
   host paths; `ResultsWriter.pointerFileName` documents that channel.
3. Add the finding to `pinnedFindings` in `PinTests.swift`, add the row above, and
   remove the `KnownFindings` entry in the same change.

After that the fixture is frozen. A pin that no longer matches its generator has not
drifted — the generator has, and that is a corpus-version conversation, not a reason
to re-mint the file.

### When the catching scenario was hand-authored

Steps 1 and 2 assume the finding came from a corpus scenario with a `KnownFindings`
entry, which is true of every T0 violation. The design-gap findings do not work that
way: a statistic-choice gap is invisible to T1 by construction (F-0014), so the ones
in fix wave C were caught by hand-authored scenarios in `WeaknessDetectionTests`
rather than by the corpus. Those pins are minted from the same construction the
weakness test uses, encoded once and then frozen exactly like any other — the pin's
authority comes from being unable to move, not from where it was born. The index
above names the weakness (`W-n`) instead of a corpus ref for these.
