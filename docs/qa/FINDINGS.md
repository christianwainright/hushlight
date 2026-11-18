# QA findings register — contraction timer

Findings from the labor-sim QA harness (decision 0021, SP-193). Numbered `F-nnnn`,
append-mostly. Statuses: `open → filed(SP-nnn) | decision-needed(nnnn) →
fixed(run ref) | accepted(decision ref) | duplicate(F-nnnn)`.

First corpus run: `20260816T164922Z` (re-rendered `20260816T170142Z`) at engine ref
`95b65b7`; corpus 1.0.0, digest `6edb6ef2…f31fad`, 408 scenarios, 358,043 probes.
Layer-J review of all 28 gallery shots completed 2026-08-16.

**Fix wave 1 (SP-194, waves A+B): run `20260816T175940Z`**, same corpus and digest.
Twelve findings closed — the Wave-A bug cluster and every presentation change
decision 0022 specifies. The run carries **zero T0 violations of any kind**, against
99 registered ones in the first run (T0-02 ×28, T0-10 ×35, T0-10a ×36), and
`KnownFindings` is now empty. Suppressions are unchanged at 46: T1-03 is measured on
the pure leg, and F-0003's lost taps were a `LaborModel` defect that the pure fold
never suffered — no verdict mathematics moved in this wave.

**Fix wave C (SP-194): run `20260816T192715Z`**, same corpus (1.0.0, digest `6edb6ef2…f31fad`,
408 scenarios, 540 scenario × leg rows) and the same `TruthCompiler` — deliberately, so
the rows stay comparable while the verdict mathematics underneath them moves. This is
the wave that implements decisions 0023–0026: the duration evidence threshold, the
frequency share, the latched verdict and windowed continuity. **Zero T0 violations of
any kind**, so the engine and `LaborOracle` still agree at all 358,043 probes across
four new fields. Eight findings closed, two opened.

The headline is mixed and the mixture is the point. Suppressions (S4) fall 46 → 38 and
the paired noise penalty falls sharply — median Δ onset under `partnerDiligent` 16.0 →
0.1 min, `typicalSolo` 42.5 → 20.7, `clockHostile` 55.7 → 9.3 — which is the duration
allowance and the bridging interval doing what they were calibrated to do. Floor
starvation is unchanged and still exonerated (p50 −235 min, 0 of 215 over threshold).
Against that: the false-met count reads 2 → 18, and **12 of those 18 are the truth
oracle judging by the mean decision 0024 replaced** (F-0028) rather than the app firing
on anything new. Onset-lag percentiles rise in several archetypes for the same reason
suppressions fall — scenarios that never fired at all now fire late, moving from the
S4 column into the S3 one, which is a strict improvement the lag table cannot show on
its own (`irregularProgressing` n 12 → 19, `sromThenOnset` 8 → 12, `precipitous`
15 → 18).

## Status table

| F | Sev | Class | Status | Summary |
|---|---|---|---|---|
| F-0001 | S3 | bug | fixed(20260816T175940Z) | Undo of a delete restores a second running record |
| F-0002 | S3 | bug | fixed(20260816T175940Z) | isRunning/runningSince disagree after a backward clock set |
| F-0003 | S4 | bug | fixed(20260816T175940Z) | Stop tap becomes a start tap; live contraction unclosable; split-brain button |
| F-0004 | S3 | design-gap | fixed(20260816T175940Z) | Stale cliff fires on a running contraction; onboarding copy over a live timer |
| F-0005 | S3 | bug | fixed(20260816T175940Z) | AXL: numerals wrap mid-figure, labels clip, verdict entirely below the fold |
| F-0006 | S4 | design-gap | fixed(20260816T192715Z) — calibrated residual | Recorded durations understate true ones; hard 60 s gate suppressed 46 scenarios (now 38) |
| F-0007 | S4 | design-gap | fixed(20260816T192715Z) | One suspect at the floor edge nulls the whole verdict |
| F-0008 | S2 | design-gap | fixed(20260816T192715Z) | Coupled contractions can pass 5-1-1 on the mean |
| F-0009 | S2 | design-gap | fixed(20260816T192715Z) — partial, see residual | No hysteresis: verdict flaps; met-reorder yanks scroll position |
| F-0010 | S2 | design-gap | fixed(20260816T192715Z) | sustainedMet ripens through a lull |
| F-0011 | S1 | bug | fixed(20260816T175940Z) | Negative figures unguarded: LaborFormat renders "-1:-10"; nothing clamps vs now |
| F-0012 | S1 | design-gap | fixed(20260816T192715Z) | Whole-episode lastInterval reads 2× against windowed average on one row |
| F-0013 | S1 | bug | fixed(20260816T175940Z) | Live Activity intent hard-codes 5-1-1 while the rule is selectable |
| F-0014 | — | harness | fixed(20260817T135952Z) | Truth oracle shares the engine's statistic; blind to statistic-choice gaps |
| F-0015 | S3 | design-gap | fixed(20260816T192715Z) | Window-edge interval drop biases averages and delays floors |
| F-0016 | S3 | design-gap | fixed(20260816T175940Z) | Partial line dies with the average: "can't say yet" renders as nothing |
| F-0017 | S3 | design-gap | fixed(20260816T175940Z) | Nothing on screen dates the figures; three unannounced cliffs follow |
| F-0018 | — | harness | fixed(20260817T135952Z) | T1-01 has no early-fire threshold; clean thumb fired 37.6 min early, unflagged |
| F-0019 | — | harness | open | Snapshot moment picker lands exactly on boundaries; two shots contradict captions |
| F-0020 | — | harness | open | Rule never seeded: no app-pass evidence exists for any rule but 5-1-1 |
| F-0021 | S1 | bug | fixed(20260816T175940Z) | Shipped partial-line copy is malformed ("…longer than 5-1-1 yet; …" double-yet) |
| F-0022 | S1 | design-gap | fixed(20260816T192715Z) — final per 0026.2 | Tick tape saturates unlabelled and stays full for the rest of labor |
| F-0023 | — | harness | open | Shots stage asserts nothing; expectedFacts never checked against the tree |
| F-0024 | — | harness | fixed(20260817T135952Z) | Corpus lacks W1/W2/W4/W10 boundary seeds; report lacks expected-detection section |
| F-0025 | — | harness | fixed(20260817T135952Z) | Tachysystole variant produces 8 contractions; "densest timeline" shot shows 2 rows |
| F-0026 | S1 | bug | fixed(20260816T175940Z) | "0 M" renders in the PATTERN slot on the first contraction |
| F-0027 | S2 | design-gap | open | Phantom taps in a coupled trough defeat the share too — a different mechanism from F-0008 |
| F-0028 | — | harness | fixed(20260817T135952Z) | T1-02 measures the gap between two frequency statistics; false-met count uninterpretable |
| F-0029 | — | harness | fixed(20260817T135952Z) | MomentScan measures a two-hour analysis window against the engine's one hour |
| F-0030 | — | harness | fixed(SP-195 phase 4) | The expectedFacts assertion executes at last, and every fact misses |
| F-0031 | S1 | bug | fixed(SP-195 phase 4) | HowItWorks miniature clips "Start" inside a fixed 48×48 frame at AX5 |
| F-0032 | — | tooling | closed — SP-195, decision 0058 | `dynamicType` reports non-scaling on nodes that measurably scale; re-measured 2026-09-05 on live views (2.34×), accepted exclusion |
| F-0033 | S0 | accepted-limitation | open | Toolbar links do not scale with Dynamic Type — system navigation furniture |
| F-0034 | S? | design-gap | open — triaged(HL-019, decision 0044) | Re-measured against today's code: 4 real `secondaryText`/`tint`/`easing`-on-`inputFill` gaps fixed; 9 named findings pixel-disproven; residual filed as F-0038 |
| F-0036 | — | design-gap | fixed(incidental, decision 0038) | `elementDetection` reads 0 across all 20 states in two full re-runs — closed by `liveHero`/tape-end-cap work that landed after this was measured |
| F-0037 | — | harness | fixed(SP-207) | Corpus's precipitous archetype never exercises fast-met: log-linear ramp reaches half-threshold only in its final ~22%, shorter than the windowed share needs |
| F-0038 | S? | tooling | closed — HL-019, decision 0057 | `hitRegion` located: `LegRowView`'s three 15.7 pt rows, proved by an `empty`-vs-`met` control; `contrast` dispositioned — 11 named findings measured, 11 pass |
| F-0039 | S2 | design-gap | fixed(decision 0046) | The slip strip's Delete rendered in system red — the app's own chrome, at the moment of a mis-tap; loudest element on screen at AX5 |
| F-0040 | S2 | design-gap | open | "How far apart" is answered by two different statistics: the call card uses the whole-episode mean, the banner legs and History's pinned legs use the trailing hour |
| F-0041 | S2 | design-gap | open | History prints start times to the minute and intervals to the second — subtracting two displayed times contradicts the printed interval on nearly every row |
| F-0042 | S2 | bug | open | History's episode summary line has no spoken form — VoiceOver reads "AVG" letter by letter on the line its own comment calls "the line a provider call reads from" |
| F-0043 | S3 | design-gap | closed — declined, HL-025, decision 0060 | The call-right-away card omits the preeclampsia family (severe headache, visual changes, epigastric pain) and second-stage pressure; wording drafted, Christian declined the additions 2026-09-05 — card ships unchanged |
| F-0044 | S2 | design-gap | open | The call summary is unreachable during the ordinary "not yet" state — it lives on a verdict banner, a 3-day recap, or inside the Clear Everything dialog |
| F-0045 | S3 | design-gap | open | A leg's met/not-met state is carried only by the filled/hollow marker; the accessibility label speaks the figure but never the state |
| F-0046 | S3 | design-gap | open | The concluded recap never says *when* the last stretch was — it can be showing a scare from months ago |
| F-0047 | S3 | design-gap | open | The same card is "For the call" in two places and "Keep a copy" in a third |
| F-0048 | S3 | question | closed — cause removed, HL-028 | Three lenses read content below the pinned slab as undiscoverable at AX5; the accessibility lens read the same frames as working as designed |
| F-0049 | S4 | design-gap | open | No bulk cleanup: junk from a three-day prodromal stretch is swipe-one-at-a-time or destroy everything |
| F-0050 | S4 | question | open — reclassified as a feature, HL-030 | No night-to-night comparison anywhere — the trend caption is scoped to the current episode by design (0043 §5) |
| F-0051 | S3 | design-gap | open | The ember tape's "1 H AGO"/"NOW" captions have no spoken override, unlike every other H/M in the app |
| F-0052 | S4 | question | closed — no change, decision 0049 | A verdict held 20 hours reads in exactly the same words as one a minute old |
| F-0053 | S4 | design-gap | fixed — HL-029 | The first sentence a first launch shows is built around a bare "?" glyph naming a toolbar icon |
| F-0054 | — | tooling | open | `ScaleBenchTests`' P99 timing threshold fails under concurrent machine load — twice this session, on changes touching only display strings, passing clean on an idle re-run |
| F-0055 | S2 | bug | fixed — HL-031 | `EpisodeTimeline`'s connector collapses at AX5: two `@ScaledMetric` fixed-width columns consume the row, and "5:00 apart" wraps to one character per line |
| F-0056 | S2 | bug | fixed — HL-032 | `HistoryRow` shreds all three of its figures mid-token at AX5 — `10:39:29 PM`, `1:02` and `+5:00` render as `10:31:0 / 9:29 2 PM` and `+5:0 / 0` |
| F-0058 | S2 | bug | fixed — HD-2 prep | `Disclaimers.reviewNotes` told App Review to "tap the large circle"; the circle became a full-width slab in decision 0036, so the one instruction a reviewer follows named a control that no longer exists |
| F-0057 | S3 | tooling | fixed — HL-033 | The *reflow* class — figures breaking inside themselves when a fixed column starves them — has no automated detector anywhere; it has now produced two S2 defects through a green AX5 leg |
| F-0059 | S3 | tooling | open — HL-058a | The AX5 audit on an **iPad** reports `textClipped` with `issue.element == nil` on History, Guidance and two timer states; the same screens pass on iPhone, the counts swing between runs (24, then 40 with the ledger disabled — which also cleared the running-state screen's 18), and the AX5 screenshots show no clipping. Unattributable, so unfixable blind. Suspected: audit heuristics against iPadOS 26's in-window chrome at regular width. |
| F-0060 | S2 | bug | fixed — HL-063 | On an **iPhone Duo** the Dynamic Island runs vertically, and its compact slot is narrower than the trailing timer's 44 pt cap: the live count wrapped inside itself, `0:04` rendered as `0:0` over `4` |
| F-0061 | S3 | tooling | open — HL-067 | The UI suite on iOS 27 simulators fails on `main` as on HL-060–065's branch: all ten `AccessibilityAuditTests`, `testRefusedCallShowsTheNumberAndCopies` and the RTL tape caps on an iPhone 17 Pro (iOS 27.0); on the iPhone Duo, also three back-button lookups through `navigationBars` that cannot see iOS 27.1's vertical bars |
| F-0062 | S3 | tooling | open — unfiled | The harness photographed nothing and said so only as "0 shots": `newest-sim.sh iPhone` picks the two-display iPhone Duo, which `simctl io screenshot` refuses without `--display`. Zero shots now fails the stage (HL-069); the picker is unchanged |

## App findings

### F-0038 · S? · tooling · **closed** — HL-019, decision 0057 (opened HL-019, decision 0044)

- **Observed:** the light + `large` leg of `AccessibilityAuditTests`, re-run twice
  independently against today's code (after F-0034's four real fixes and the
  toolbar/slab/miniature findings pixel-disproven — see F-0034's own disposition
  below). What is left: ~50 `contrast` findings and all 15 `hitRegion` findings,
  every one reported as `unknown element` — `issue.element` is nil, so there is no
  frame to screenshot and no `debugDescription` to diff against the view tree.
- **It is reproducible, not noise.** Two full 18-state runs, same build, produced
  near-identical per-state counts (16 of 18 states exact, two off by one) — the
  same order of stability the passing legs already show elsewhere in this harness.
  Whatever is firing is a real, repeatable signal, not audit jitter.
- **`hitRegion`'s shape is the most tractable, and it still resisted.** All 15
  `hitRegion` findings split 3-3-3-3-3 across exactly the five states where
  `LegRowView` (`Hushlight/LegRows.swift`) renders three rows — the verdict
  banner's legs and History's `PinnedLegHeader`, both built on the same shared
  component. Tested directly (decision 0038's method): `.frame(minHeight: 44)` on
  each row, rebuild, re-run `testMetVerdictIsAccessible` alone. `met`'s
  `hitRegion` count held at 3, unchanged. **Exonerated**, the same negative result
  F-0036's own connector-row test produced against `elementDetection` — the
  coincidence of a matching count is not evidence of a cause, twice now in this
  file.
- **Scrolled states name a moving target.** After the four `inputFill` fixes landed,
  `guidance/scrolled` still named one contrast failure — Guidance's "Call right
  away" header, the one call site the fix should have cleared. Isolating it
  (`testGuidanceIsAccessible` alone, `secondaryTextOnFill` temporarily forced to
  `primaryText`'s own value — ~11:1, no ambiguity left in the number) made that
  finding disappear, but the same state then named two *different* elements
  instead — "Breath pacer while timing" and its toggle's caption, both drawn in
  unmodified, already-passing tokens (`secondaryText`/`primaryText` on
  `Palette.screen`, 5.63:1 / 14.09:1) that this run had nothing to do with. The
  fix was not tested by that swap; the *state* was. `guidance/scrolled` scrolls a
  long page to its end over several synthesized swipes, and which content the
  audit happens to sample when it fires is not fixed run to run — a second axis
  of instability on top of the reproducibility this entry otherwise measured
  (see below), and further reason "unknown element" cannot be chased one finding
  at a time.
- **Every *named* finding in the same two runs turned out to be a false positive**
  (see F-0034's disposition), which is the case *for* treating this pile as more
  of the same class rather than a hidden real bug — and the case *against* is that
  "unknown element" cannot be pixel-checked the way a named one can, so that
  conclusion is inference, not measurement, and this entry says so rather than
  rounding it up to a disposition.
- **Disposition:** filed open. Diagnosing an anonymous `SwiftUI.AccessibilityNode`
  needs a tool that can walk the live element tree or attach an inspector to a
  running audit — Xcode's Accessibility Inspector, chiefly — which this session
  did not have (CLI `xcodebuild`, `simctl`, and screenshots only). Left for a
  session with that tool, or for a future SDK whose audit names what it finds.

- **Resolved 2026-09-05 (decision 0057), by two instruments this entry did not try.**

  **An older runtime names more.** The same leg, same build, same device model
  (iPhone 16 Pro), on iOS 18.5 versus 27.0: 79 findings / 62 unknown / **17 named**
  against 76 / 69 / **7 named**. The pile is not a Liquid Glass artefact — it
  reproduces below 26 — but 18.5 attaches role, frame and label to ten more findings
  than 27.0 does.

  **`hitRegion` is `LegRowView`, and this entry's original hypothesis was right.** The
  count is 3 in each of six states, identical on both runtimes. The elimination test
  above changed the rows and saw the count hold, and read that as exoneration. The
  control it never ran settles it: **`empty` reports zero `hitRegion` findings while
  carrying the same three undersized toolbar buttons as `met`** (`History` 62.7×28.3,
  `Guidance` 39.7×39.0, `How it works` 34.0×34.0), so the toolbar cannot be the cause —
  and what `met` and `history` have that `empty` does not is exactly three
  non-interactive rows at **15.7 pt tall**, labelled `apart`, `long`, `holding`.
  Measured directly by `HushlightUITests/SmallTargetDiagnostics`, the live-tree browser
  this entry said it needed. Count, states and frames now agree.

  *Not fixed, deliberately.* Those rows are read-only figures (`type=1`, no action);
  Apple's 44 pt bar is a touch-target rule. Meeting it would add ~85 pt to the verdict
  banner to enlarge something nobody taps. Accepted limitation, with the measurement.

  **`contrast` disagrees with the pixels.** Six newly-named findings are the readout's
  em dashes; sampled at the audit's own reported frame, the glyph is `(107, 97, 84)` —
  exactly `Palette.secondaryText` — on `(250, 246, 239)` — exactly `Palette.screen` —
  for **5.63:1**, matching `PaletteContrastTests` to the digit and clearing AA. Eleven
  named contrast findings on this leg have now been measured and eleven pass, two of
  them (`CALL RIGHT AWAY — PATTERN ASIDE`, the slip sentence) being call sites F-0034
  already corrected and which still fire. The category stays reported and
  un-suppressed; it does not gate.

  **Still open, and smaller:** the `unknown element` residue neither runtime names.

### F-0037 · — · harness · fixed(SP-207)

**Found by** SP-207's own differential sweep: across the corpus's 28 precipitous
scenarios and 12,063 probe ticks, the new fast-met state (decision 0040) was true on
exactly zero. Not a bug in the state — ten boundary tests and the live seed confirm
it fires on the shape 0040 describes — but a hole in the corpus: `Archetypes
.precipitous` ramps intervals log-linearly from 8:00 down to 1:48, so gaps sit
inside the half-threshold only in the ramp's final stretch, shorter than the
windowed two-thirds share can clear. By then the trailing window is uniformly tight
and the *ordinary* verdict already serves it. A labor that is 2:00 apart from its
first contraction — 0040's motivating shape — had no corpus representative at all,
so fast-met had agreement evidence everywhere (zero oracle disagreement) and
detection evidence nowhere.

**Disposition:** corpus 3.1.0 — `fastFromTheFirstContraction` joins the boundary
battery (exact arithmetic: 23 × 120 s starts, 80 s durations, 44 minutes), with
`WeaknessDetectionTests.fastFromOnsetFiresFastMetAndNeverMet` pinning that the
engine and the oracle both fire fast-met and neither reaches `met` inside the hour.
Battery 41 → 42, standard corpus 413 → 414, digest re-pinned.
### F-0054 · — · tooling · open (HL-022)

`patternP99StaysUnderFiftyMillisecondsAt500Records` failed during HL-007 and again
during HL-022 — both times on diffs that touched only display strings and catalog
wiring, never `PatternAnalysis`; both times passing on a re-run with the simulator
idle. The engine is not slow; the machine was busy.

A wall-clock threshold that depends on what else is running teaches its reader to
re-run a red suite instead of investigating it, which is precisely the habit that lets
a real regression through one day. Worth converting to a *relative* measure — work per
unit against a baseline captured in the same run — or demoting it to advisory output
that never fails the suite. Filed rather than fixed: changing how the harness judges
performance deserves its own decision, not a drive-by during a copy fix.

### F-0055 · S2 · bug · fixed (HL-031 — found while verifying HL-028)

At AX5 the timer's timeline is unreadable. `EpisodeTimeline.connector` lays out a row
as `[leadingColumnWidth spacer][nodeDiameter rule][Text("5:00 apart")][Spacer]`, and
the first two are `@ScaledMetric`: 76 pt relative to `.body` and 26 pt relative to
`.caption2`. At AX5 they grow to roughly 235 pt and 90 pt of a 402 pt screen, so the
text is proposed a sliver — it wraps to **one character per line**, reading as a
vertical strip of letters down the right edge, and the row's height blows out to
several hundred points of black. `node(_:ordinal:intervalToNext:)` shares the same two
fixed columns but usually has nothing after them (the CHECK flag is absent on a healthy
row), so the nodes look fine and only the connectors collapse.

The mechanism is the one decision 0048 §Boundaries already names — widening that
column was measured pushing the screen into horizontal overflow at AX5 — but the
finding is the other half of it: at AX5 the column is *already* too wide for what has
to sit beside it, at the shipped 76 pt, with nothing widened. `LegRowView` takes a
`dynamicTypeSize.isAccessibilitySize` branch and stacks; `EpisodeTimeline` has no such
branch anywhere, which is the real defect.

Filed rather than fixed: it was found during HL-028's verification, it is not what
HL-028 is about, and DoD §5 says additions enter the backlog first. Worth noting that
it makes HL-028 *worse* — several hundred points of empty row is a lot of scrolling
between the reader and the content below the fold.

**Disposition (HL-031):** fixed by giving `EpisodeTimeline` the accessibility-size
branch `LegRowView` has always had. At AX5 the fixed columns go and the row stacks —
the dot leads, the figures follow it, and the connector keeps only its rule, which
lands under the dot because the dot now leads that row too, so the thread still runs
true with no fixed gap holding it there. The interval also takes `.fixedSize(horizontal:
false, vertical: true)`: it is the figure the row exists to print and should not be the
element that yields when the row runs short, which is how it came to be rendered a
character at a time rather than simply wrapping. One further change the collapse had
been hiding: stacked, the interval lands at the same indent and the same `.label`
weight as the node's own clock time directly above it, so `5:00 apart` and `9:57 PM`
were distinguished by the word *apart* alone — at accessibility sizes the rule now
spans the row, and an unbroken thread beside a figure marks it as being about the space
between two contractions rather than about either one.

**Why nothing caught it, and what does now.** Apple's audit does not flag it (reflowed
text is not clipped text; a tall row is not a violation), the connector is
`accessibilityHidden` by design so XCUI cannot query the collapsed element, and the
nodes looked fine throughout because they usually have nothing after their two columns
at all. `LayoutInvariantTests.testTimelineConnectorsDoNotCollapseAtAX5` asserts on the
one thing the collapse cannot hide — the hole it leaves between the two nodes it
separates — bounded by the neighbouring rows rather than by a constant: a hairline and
one short phrase have no business being taller than a row carrying a duration, a clock
time and a dot.


### F-0056 · S2 · bug · open (HL-032 — found while verifying HL-030)

F-0055's sibling, one screen over, and worse. `HistoryRow` is an `HStack` of three
`dataText(.row)` figures — start time, duration, and the interval to the previous
record — with a `Spacer` between the second and third and **no accessibility-size
branch**. At AX5 all three shred mid-token: a row reading `10:39:29 PM · 1:02 · +5:00`
renders as

```
10:31:0    +5:0
9:29 2       0
   PM
```

Reproduced on `-seedLabor511` with nothing else changed, so it long predates HL-030 and
HL-031; it was simply never looked at, because the walkthrough's accessibility lens read
the *timer* at AX5 and History's rows are several screens further in.

Worse than F-0055 in one specific way: F-0055 mangled a decorative connector whose
interval is spoken elsewhere. These are the record rows — the times a woman reads back
to a nurse over the phone — and decision 0048 deliberately widened them by putting
seconds on the start time, precisely so a printed gap could be checked against two
printed times. At AX5 that check is impossible.

The fix is HL-031's, applied one file over: the same
`dynamicTypeSize.isAccessibilitySize` branch `LegRowView` and now `EpisodeTimeline`
take. Filed rather than fixed under DoD §5 — HL-030 was the item in flight, and this is
neither its cause nor its consequence.

**Disposition (HL-032):** fixed with that branch, stacking the three figures and
preserving their reading order exactly — when it happened, how long it ran, how long
since the one before. A row that reordered itself at one type size and not another would
make two readers describing the same screen disagree about it.

**No layout invariant, and the reason is worth recording rather than papering over.**
F-0055 was pinned by asserting on the *hole* its collapse left between two nodes. This
defect leaves no such hole: broken, the three figures sit side by side and each wraps to
about three lines; fixed, they sit stacked as three single lines. **Both rows are about
three lines tall.** Frames cannot tell them apart, XCUI cannot see inside a `Text` to
count its line breaks, and Apple's audit does not flag reflowed text as clipped (the
distinction `LayoutInvariantTests` opens by naming). A test written anyway would pass
for the wrong reason, which this repository has already decided is worse than no test —
so what is filed instead is the *coverage* gap that let this live: F-0057.


### F-0058 · S2 · bug · fixed (found rendering `reviewNotes` for App Store Connect)

`Disclaimers.reviewNotes`' HOW TO TEST section opened: *"Tap the large circle to start a
contraction and again to end it."* The circle stopped existing in HL-003 slice 1 —
decision 0036 turned it into a full-width bottom slab, and the label became Start / End.
An App Review tester following the only instruction the notes give would have gone
looking for a control the app has not had for several items.

Caught only because the notes had to be *rendered* to be pasted: the source is a
multi-line Swift literal with interpolation and backslash continuations, so "paste
verbatim from `Disclaimers.swift`" — what the listing doc says — is not actually
possible without running it. Rendering it made the stale sentence obvious. It had been
read past in the file itself more than once.

**Why the existing test could not see it.** `DisclaimersTests` pins these strings
against `neverSays` — no diagnosis, no instruction, no "you are in labor" — which is a
check on what the copy *must not claim*, not on whether it describes the app that
exists. Every word of "tap the large circle" passes that bar. The same gap covers the
rest of the notes: their screenshot order, control names and feature list are all prose
about a UI, verified by reading.

Fixed to name the control as it is ("the large button across the bottom of the screen —
labelled Start, then End"). Worth a standing habit rather than a test: **any decision
that renames or reshapes a control is a decision that may have invalidated the review
notes**, and 0036 is the proof.


### F-0057 · S3 · tooling · fixed (HL-033 — what actually let F-0055 and F-0056 live)

**First, a correction, because the obvious explanation is wrong and acting on it would
have wasted the fix.** The initial reading of this was "the AX5 leg never leaves the
timer screen". That is false. `AccessibilityAuditTests.testHistoryIsAccessible` taps
through to History under `-seedLabor511` and audits it twice, at rest and scrolled, and
`testGuidanceIsAccessible` and `testHowItWorksIsAccessible` do the same for their
screens. The coverage exists and has existed. F-0056 was rendering *inside* an audited
state, on a runner that reported zero findings.

The real gap is narrower and worse: **nothing in this repository can detect reflow.**
Both F-0055 and F-0056 are the same defect class — a fixed-width column, scaled by
`@ScaledMetric`, starving the figure beside it until that figure breaks *inside itself*
— and every check pointed at it is structurally blind:

- **Apple's audit** distinguishes clipped text from reflowed text and only reports the
  first. A figure that wraps to one character per line is not clipped; every glyph is
  present, in the wrong order. `LayoutInvariantTests` opens by naming this distinction,
  and it is the reason that file exists at all.
- **`LayoutInvariantTests`** could see F-0055 only indirectly, by measuring the hole the
  collapse left *between* two nodes. F-0056 leaves no hole (see its own entry), so the
  same trick does not transfer. Five invariants, all of them the timer screen.
- **`pseudo-check.sh`** doubles every string, which is precisely the right stress for
  this class — and it shoots the timer screen only, at XL rather than AX5, and produces
  screenshots for a person to look at rather than an assertion.

Two S2 defects have now shipped through that gap on a leg reported green.

**What would actually close it.** Not more audit coverage — the audit cannot see this.
The tractable detector is a lint, in the idiom this repo already uses for its other
invariants (`lint-literals.sh`, `lint-logging.sh`, `lint-localizable.sh`): a view that
puts two or more `.dataText(.row)` figures on one line and does not take a
`dynamicTypeSize.isAccessibilitySize` branch is the shape of both defects, and it is
greppable. Three views have needed that branch so far — `LegRowView`, `EpisodeTimeline`,
`HistoryRow` — and each was found by a person looking at a screenshot. The fourth should
be found by the build.

**Disposition (HL-033):** `scripts/lint-row-figures.sh`, called by `gate.sh` and CI,
with the rule stated in CLAUDE.md §Conventions beside the literal ban. A file printing
two or more `.dataText(.row)` figures and never mentioning `isAccessibilitySize` fails.

Validated against history rather than asserted: run over `EpisodeTimeline` at
`9da046b~1` it fails; over `HistoryScreen` at `a181331~1` it fails; over the current tree
it passes on every file. The two real defects and no others, with no waivers needed yet.

It is a *shape* check and its own header says so — grep does not know what an `HStack`
is and cannot prove a layout reflows. It asks the one question whose answer was "no" both
times: did anyone think about accessibility sizes in this file at all? A row that
genuinely cannot starve waives itself in a comment mentioning `isAccessibilitySize` with
the reason, the same escape the other lints give.


### A1.3 · The rebuilt night — five-lens walkthrough (2026-08-26)

Every surface the A1.2 walkthrough examined has been replaced since: the disc became a
slab, the tick tape became the ember tape, the verdict became dawn, the header dates
itself, closure exists, the call card exists. This pass drove the current app on glass —
29 states across appearances, type sizes, and live taps — and ran five lenses over the
same corpus: the 2am mother, the partner on the phone to triage, the midwife, an
accessibility pass, and the third night of prodromal labor. Every finding below was
verified against source before filing; the disagreements between lenses are recorded
rather than resolved by fiat.

**F-0039** is fixed here (decision 0046). The rest are filed as HL-021…HL-029.

**What the lenses agreed on.** Three of five independently flagged content sitting below
the pinned slab at accessibility sizes — the rest-licensing sentence, the verdict's call
clause, the recap's two buttons. The accessibility lens, looking at the same frames,
judged them working as designed: content stops cleanly at an opaque bar and is one scroll
away, which is what decision 0027 and HL-007 deliberately built. **That disagreement is
F-0048 and it is not resolved.** It is the difference between "reachable" and "found",
and it wants a human's eye on a real phone rather than a third opinion from a screenshot.

**What only one lens could see.** The partner lens found the deepest defect (F-0040):
`CallSummary` reads the whole-episode mean by explicit design ("a call script judges the
whole stretch, not the last hour") while the banner directly above it reads the trailing
hour. On a tightening pattern those differ, so a partner can read one number off the
screen, tap For the call for the exact wording, and be handed another — mid-call, to a
nurse. Its sibling F-0041 is visible in a screenshot anyone could have taken: rows read
7:52 PM and 7:46 PM with "+5:30" printed beside them, because the display drops seconds
the arithmetic keeps.

**What the app got right, per the lenses that were trying to break it.** The midwife
found no diagnosis language anywhere and confirmed the fast-labor branch fires exactly as
decision 0040 specifies without inventing a threshold; the accessibility lens confirmed
colour is nowhere the sole carrier of meaning and that decision 0038's spoken-counterpart
rule holds everywhere except the three sites above; the long-haul lens confirmed the
3-day closure threshold never ambushes a labor mid-stretch and that the recap assumes no
outcome, ever.


### F-0001 · S3 · bug · fixed(20260816T175940Z)
- **Observed:** `boundaryBattery-advRestoreWhileRunning*` (store + model), T0-10: two
  records with `endedAt == nil`.
- **Mechanism:** `restoreContraction` restores a running record verbatim, bypassing
  `beginContraction`'s single-running guard.
- **Disposition:** SP-194. Fixed in `LaborStore.restoreContraction`: a restore that
  would stack a second open record comes back **closed at its own start** instead.
  The row survives — mis-taps are expected mid-labor and "undo restores it" has to
  stay true — as a zero-length contraction its owner can see and delete, while the
  single-running invariant holds. Inventing an end from the clock would record a
  moment nobody marked. Mirrored into `ReplayEngine.fold` and `OracleMath.fold` in
  the same change. **Pin:** `F-0001.json` (`boundaryBattery-advRestoreWhileRunning`).

### F-0002 · S3 · bug · fixed(20260816T175940Z)
- **Observed:** `*-chaotic-*`, `*-clockHostile-*`, restore route (model), T0-10a.
- **Mechanism:** backward clock set stamps a new start earlier than a completed one;
  `isRunning` reads `contractions.last`, `runningSince` reads `last(where:)`.
- **Disposition:** SP-194 — one definition of "running" everywhere. Both now derive
  from a single `LaborModel.running`, so they cannot diverge. T0-10a survives as a
  sentinel that goes red the moment anyone gives "running" a second definition.
  **Pin:** `F-0002.json` (`classicNullipara-v0-clockHostile-r0-fiveOneOne`).

### F-0003 · S4 · bug · fixed(20260816T175940Z)
- **Observed:** model leg, T0-10 + T0-02 across 7 scenarios; model snapshots lose up
  to half the contractions (29 vs 54 rows). User-visible face confirmed in code: the
  button renders elapsed from `runningSince` but style/ring/label from `isRunning` —
  an idle-styled button showing a live count and "Tap when it ends", announced to
  VoiceOver as "Start contraction".
- **Mechanism:** in the F-0002 state a stop tap calls `beginContraction`, which
  no-ops against the still-running older record: the live contraction can never be
  closed from the UI; every later tap no-ops; `undoAction` sits `.started(id:)` on
  the live record — one undo from deleting it.
- **Disposition:** SP-194. Falls out of F-0002: the button follows the corrected
  `isRunning`, so the stop tap ends the running record. The split-brain state is
  unconstructable — the button's style, label, count and VoiceOver announcement all
  read one source. **Pin:** `F-0003.json`
  (`classicNullipara-v0-chaotic-r0-fiveOneOne`), plus
  `LaborModelTests.aStopTapAfterABackwardClockSetEndsTheRunningContraction`, which
  replays the clock-set-back sequence and asserts the tap ends B, the timeline grows,
  and `undoAction` is `.ended(B)`.

### F-0004 · S3 · design-gap · fixed(20260816T175940Z)
- **Observed:** `light-m/multi-day-latent-exhausted--stale.png`: "No contractions
  yet. Tap the button when one starts" (first-launch onboarding copy) with em-dash
  columns and ghost timeline, beside a button reading **121:00 · Tap when it ends**,
  with 70 records in History — 29 h into latent labor.
- **Mechanism:** staleness (`now − latest start > 2 h`) empties the pattern even
  while a record is running; the empty state renders onboarding copy whenever the
  pattern is empty, with no memory that history exists.
- **Disposition:** decision 0022 §1 and §2, both halves landed in SP-194. The
  staleness clock now considers only ended contractions — an open record means the
  episode is live by definition — and the empty state reads as a return ("Last
  contraction ended {n} ago.") whenever `LaborModel.lastEndedAt` says the store has
  been used before. `LaborOracle` and the harness's own T0-13 assertion carry the
  same exception. **Pin:** `F-0004.json`
  (`multiDayLatent-v0-exhaustedSolo-r0-fiveOneOne`), which asserts both halves at
  `latestStart + 7260`.

### F-0005 · S3 · bug · fixed(20260816T175940Z) (§8 gates are law)
- **Observed:** all dark-axl shots; worst
  `classic-nullipara-typical--verdict-met-plus-2m`: "2:58" wraps as "2:5/8",
  "1:05" as "1:0/5", labels clip mid-glyph ("INTER/VAL"), and **the met banner is
  entirely below the fold — the met, one-short-of-floor, and 45-min-stale screens
  are indistinguishable in the first screenful at AXL.**
- **Mechanism:** three-across readout kept at accessibility sizes; `guidance()`
  rendered after `readout()` regardless of type size.
- **Disposition:** SP-194, decision 0022 §5. The readout is a `ViewThatFits` that
  stacks the three columns when they no longer fit across, each numeral `fixedSize`d
  so a figure can never break mid-value, and at
  `dynamicTypeSize.isAccessibilitySize` `guidance()` renders above `readout()`
  whatever the state. No fixed frame heights, no `minimumScaleFactor` on data
  numerals — reflow, never truncation.

### F-0006 · S4 · design-gap · open — the run's headline
- **Observed:** T1-03 ×46 (exhaustedSolo 23, chaotic 16, typicalSolo 5,
  clockHostile 2); truth fires in 221 scenarios, the app never fires in 89; five
  promoted verdict-met moments never resolved at any probe, including precipitous
  under an exhausted thumb (48.6 min suppressed on the fastest labor family).
- **Mechanism (corrected by Layer J — the floors are exonerated):** floor starvation
  p50 is −235 min, 0 of 215 over threshold — the evidence floors are NOT the
  bottleneck. The mechanism is **duration understatement**: users tap start late
  (reaction + certainty lag; noise model medians 3–25 s by profile) with no matching
  end lag, so recorded duration ≈ true duration − start latency, while start-to-start
  intervals cancel the lag out. `durationMet` is a hard `≥ 60 s`: a true 75 s
  contraction recorded as 55 s is permanently unmet. Compounded by the lost-tap
  chain (F-0003) under chaotic thumbs.
- **Disposition:** SP-194 wave C, decision 0023 §1. `GuidelineRule.durationEvidenceThreshold`
  (50 s) is what `durationMet` reads; `durationThreshold` (60 s) remains as the rule
  the copy quotes, and the Guidance explainer now states the allowance rather than
  leaving a reader to discover a met verdict beside a printed 0:55. Displayed figures
  are unchanged — a 55 s average still prints 0:55.
- **Residual, stated honestly (20260816T192715Z): 46 → 38 suppressions, not zero, and the
  allowance is not the only thing that moved.** By profile: exhaustedSolo 23 → 19,
  chaotic 16 → 15, typicalSolo 5 → 3, clockHostile 2 → 1. That is decision 0023's
  calibrated position doing exactly what it was calibrated to do and no more: a 10 s
  allowance cannot recover a thumb whose median start latency is 20–25 s, and the
  exhausted and chaotic profiles are precisely those thumbs. Buying them back would
  mean a threshold at or under 40 s, which stops distinguishing labor from
  Braxton-Hicks — the trade decision 0023 declined to make.
- **And a countervailing effect, on the record:** two archetypes went *up*
  (classicNullipara 5 → 6, multiDayLatent 6 → 7) while precipitous fell 13 → 10 and
  sromThenOnset 5 → 3. Decisions 0024 and 0026 are strictly *stricter* than what they
  replaced — a share can refuse a pattern whose mean passed, and continuity can refuse
  an hour a lull ran through — so the net −8 is a duration recovery partly offset by
  two new refusals. The wave moved four things at once and the suppression figure is
  their sum; separating them needs per-decision ablations, which belong with F-0014's
  truth work rather than to a number quoted here as if it were one mechanism.

### F-0007 · S4 · design-gap · fixed(20260816T192715Z)
- **Observed:** W6 detection: 6 in window, usable durations exactly 3, one forgotten
  stop → 2 usable → `averageDuration` nil → verdict nil despite 6 real taps.
- **Mechanism:** suspect exclusion × duration floor at the edge. Sharpest single
  instance of the F-0006 family; low corpus prevalence but total effect.
- **Disposition:** SP-194 wave C, decision 0023 §2. With ≥6 in window and ≥1 suspect
  among them the usable-duration floor relieves from 3 to 2 — a forgotten stop-tap is
  itself evidence a contraction happened and ran long, and it must not be able to null
  the reading it belongs to. The relief stops at two: one usable duration is still the
  single-point average every floor here exists to refuse
  (`PatternAnalysisTests.oneUsableDurationFailsEvenWithASuspectPresent`), and it needs
  the window's own evidence floor behind it (`…theSuspectReliefNeedsTheFullWindowEvidenceFloor`).
  `LaborOracle` carries the identical relief. **Pin:** `F-0007.json`.

### F-0008 · S2 · design-gap · fixed(20260816T192715Z)
- **Observed:** W2 detection scenario (hand-authored): alternating ~2/8 min → mean
  ≤ 5:00 → `frequencyMet`. Corpus note: zero sampled coupling scenarios false-fired
  this run (their means sat above threshold) — W2 is validated by the seeded test
  only; see F-0024.
- **Disposition:** SP-194 wave C, decision 0024. `frequencyMet` is a share: at least
  two-thirds of in-window start-to-start intervals at or under the rule's threshold,
  compared as `within × 3 ≥ total × 2` so the exact 4-of-6 case is decided by integers
  rather than by a Double's rounding of 0.666…. A textbook 4:50 stream passes at
  100 %; strict 2/8 coupling sits at 50 % and does not. The displayed average stays the
  mean — it is the provider conversation's vocabulary — now backed by a boolean
  symmetry cannot game. **Pin:** `F-0008.json` (the textbook 2/8 form the decision
  names). The pin asserts the engine rather than a T1 false-met count on purpose:
  `TruthCompiler` still judges the true stream with the same mean (F-0014), so truth
  cannot condemn this shape until that changes.
- **Not closed by this:** the *phantom-tap* coupling the W2 harness scenario actually
  models. See F-0027 — it is a different mechanism and it survives the share.

### F-0009 · S2 · design-gap · fixed(20260816T192715Z)
- **Observed:** 61 scenarios ≥1 met-flap (histogram 347/56/4/1); churn to 2.68/h.
  Layer J adds the interaction cost: the met-reorder animates the verdict block in
  above the reader's scroll position mid-contraction — and can bounce straight back.
- **Disposition:** SP-194 wave C, decisions 0024 and 0025. Two things closed it, and
  the order matters: the share (0024) removed the *mechanism* for the archetypal
  probe — a 270/330 alternation straddling the threshold now sits at a ~50 % share and
  reads false throughout instead of oscillating across a line — and the latch (0025)
  covers what a share can still produce near its own 2/3 boundary.
  `GuidelineStatus.presentedMet` turns true the instant `met` does and holds until
  `met` has been continuously false for ten minutes, derived statelessly from
  (records, rule, now) by re-evaluating the raw verdict at 30 s steps across the
  trailing ten minutes. Each past step is judged against `PatternAnalysis.records(_:asOf:)`
  — the records **as they stood then** — because judging a past instant with the
  present record set would let contractions from the last ten minutes vote in a window
  they had not joined, and latch onto a verdict that was never raw-true. The screen's
  banner, met-reorder and spring animation all key on `presentedMet`; the raw verdict
  is unchanged and is still exactly what the oracle checks. **Pin:** `F-0009.json`.
- **Residual, stated:** `presentedMet` lives on `GuidelineStatus`, so it cannot exist
  where the evidence floor withdraws the status entirely — a drained window still
  removes the banner at once rather than ten minutes later, and the banner's live
  figures are nil there anyway. The latch smooths a verdict that is rendering; it does
  not keep one rendering. Decision 0025 §3's "the banner leaves once" holds for decay
  through the dimensions, not for decay through the floor.
- **And that residual is most of the measured flapping.** Instrumented over the whole
  corpus at 20260816T192715Z: of 69 flaps inside `mustFire` zones, **54 are `met → noVerdict`**
  (the status disappearing) and only **15 are `met → partial`** (a dimension wobbling,
  which is what the latch holds). F-0009's original triage read the flaps as mean drift
  and decision 0025 was written against that reading; the corpus says the dominant
  mechanism is the evidence count draining out of the window — W3/W5's cliff, which
  this wave did not touch. So the latch is implemented and correct (pinned in
  `PatternAnalysisTests.theRawVerdictFlipsWhileThePresentedOneHolds` and
  `MetricsTests`) and the aggregate barely moves: 74 flaps before, 69 after, with the
  raw series at 67. **Latched exceeding raw is not a bug**: holding a verdict moves its
  eventual drop later, and a drop that used to land in a gray zone can land inside a
  `mustFire` one, where T1-04 counts it. Closing the rest of F-0009 means giving the
  drained window a presentation of its own — next wave, and a decision first.

### F-0010 · S2 · design-gap · fixed(20260816T192715Z)
- **Observed:** W4 detection: six quick taps + 50-min lull (2590 s silence) + one
  tap → "sustained 1 h" true.
- **Mechanism:** `patternLength = now − episodeStart`, lull-blind.
- **Disposition:** SP-194 wave C, decision 0026. `sustainedMet` now requires the hour
  **and** continuity: no in-window start-to-start gap may exceed 3× the rule's interval
  threshold (900 s at 5-1-1, 720 at 4-1-1, 540 at 3-1-1 — the cap scales with the
  cadence the rule promises, because a fifteen-minute hole is jitter at one and five
  missed cycles at another). Both sides pinned at each rule
  (`PatternAnalysisTests.aGapAtExactlyTripleTheSpacingStillSustains`). `patternLength`
  itself is untouched: it answers a different question and 0022 dates it. **Pin:**
  `F-0010.json`. See F-0022 for the instrument that asserted this.

### F-0011 · S1 · bug · fixed(20260816T175940Z)
- **Observed:** W8 family. Layer J verified the render path: `LaborFormat` has no
  negative handling — `minutesSeconds(−70)` → "-1:-10", `hoursMinutes(−3700)` →
  "-1 M"; only the button clamps (`max(0,…)`). No corpus scenario yet moves `now`
  before `episodeStart` (see F-0024).
- **Disposition:** SP-194 — clamped on both sides. Every `LaborFormat` entry floors
  at zero (`minutesSeconds`, `hoursMinutes`, `spoken`, and the new prose `gap`), and
  `PatternAnalysis.patternLength` is `max(0, now − episodeStart)` with `LaborOracle`
  carrying the identical floor, so the differential test still refereess it. Tested
  both sides: `PatternAnalysisTests.patternLengthFloorsAtZeroWhenTheClockRunsBackwards`
  and `PinTests.noProbeEverProducesANegativeFigure` over every pin's probe grid.
- **Not done here:** the corpus scenario (multi-hour back-set, timezone-correction
  shaped) stays with F-0024's harness batch — adding a scenario bumps the corpus
  version, and this wave deliberately kept the corpus row-comparable.

### F-0012 · S1 · design-gap · fixed(20260816T192715Z)
- **Observed:** `back-labor-coupling--last-interval-whipsaw`: `INTERVAL 10:53`
  beside `LAST 20:58` — a 2× disagreement about "the interval" on one screen; the
  mean is a value that never occurs in a bimodal pattern.
- **Disposition:** SP-194 wave C, decision 0024 §2 — Layer J's own smallest fix. The
  INTERVAL column's detail slot now renders the in-window min–max range
  (`LaborPattern.intervalRange`, formatted "5:31–20:58" by `LaborFormat.range`), a raw
  fact that makes bimodality visible instead of hiding it inside a mean. It is rendered
  even when both ends coincide — a metronome is information too, and a slot that
  changes shape to save four characters is a slot that has to be re-learned.
  `lastInterval` keeps its whole-episode definition and stays on screen where it always
  belonged: printed on the timeline connector between exactly the pair it measures, so
  it reads as the newest sample of a visible spread rather than as a rival average.
- **Beyond the finding:** column details were invisible to VoiceOver — the readout
  combines its children and spoke only label and value — so the spread would have been
  a sighted-only fix. `ReadoutColumn` gained `spokenDetail`, and INTERVAL and PATTERN
  now speak theirs.

### F-0013 · S1 · bug · fixed(20260816T175940Z)
- **Observed:** T2-08 sentinel context; `StartStopContractionIntent` hard-codes
  `.fiveOneOne`.
- **Disposition:** SP-194 — the intent reads `GuidelineRule.persisted()`, and the
  defaults key is now named once (`GuidelineRule.defaultsKey`) rather than copied
  into `LaborModel`. `LiveActivitySentinelTests` gained the reconciliation half of
  T2-08: one key, all three rules round-tripping, and an unreadable stored value
  falling back rather than trapping mid-labor.
- **Still open behind it:** F-0020 — no app-pass evidence exists for any rule but
  5-1-1, because `LaborSeedSnapshot` carries no rule. The intent and the app agree
  now; proving it on glass is the harness batch's job.

### F-0015 · S3 · design-gap · fixed(20260816T192715Z)
- **Observed:** W3 detection; contributes to onset lag (classicNullipara p99
  75.7 min).
- **Mechanism:** first in-window contraction's bridging interval dropped.
- **Disposition:** SP-194 wave C, decision 0023 §3. The interval basis is now the
  window **plus the one record immediately before it**: an interval whose *later*
  endpoint starts in-window is a gap the last hour contains, and it is the gap the
  reader just lived through. So `n` in-window records yield `n` intervals whenever
  anything precedes the window, and `n−1` only at the very start of an episode, where
  there is nothing to bridge from — both cases pinned in the flipped W3 test. The same
  basis feeds the frequency share, the interval range and 0026's continuity check, so
  "in-window interval" has one definition rather than three.

### F-0016 · S3 · design-gap · fixed(20260816T175940Z) (new — Layer J)
- **Observed:** `braxton-hicks--peak-evidence` (DURATION —, no sentence),
  `chaotic-forgotten-stop--suspect-present`, and the +47 min drained-window cliff:
  when `averageDuration` (or the verdict) goes nil, the guidance area renders
  *nothing* — the partial line requires the averages too.
- **Mechanism:** `guidance()` returns empty below the verdict floor; "we can't say
  yet" is expressed as silence at exactly the moments a user most needs orientation.
- **Disposition:** SP-194, decision 0022 §4 (presentation, no verdict math). The
  guidance area now renders on every live episode; the four shapes are listed under
  F-0021. `LaborPattern` gained `inWindowCount` so the line can say how much evidence
  it speaks from without a second copy of the window rule living in a view.

### F-0017 · S3 · design-gap · fixed(20260816T175940Z) (new — Layer J)
- **Observed:** `classic-nullipara-typical--drained-window-45m`: averages, LAST, and
  banner all render 45-minute-old facts in the present tense; the only timestamp is
  SINCE (13 h ago); then three unannounced cliffs at ~+47/+90/+121 min.
- **Disposition:** SP-194, decision 0022 §3 — the header reads
  "CONTRACTIONS · SINCE 7:42 PM · LAST 45 M AGO", one `sectionLabelText()` in the
  role SINCE already used, with a spoken accessibility label. A raw fact about the
  record, so floor-exempt. Withheld while a contraction is running (the live count
  already dates the screen) and under a minute, where "LAST 0 M AGO" would be a zero
  in a data slot and nothing has gone stale anyway.

### F-0021 · S1 · bug · fixed(20260816T175940Z) (new — Layer J)
- **Observed:** shipped partial line renders *"Not at 5-1-1 yet — intervals are
  longer than 5-1-1 yet; contractions are shorter than a minute on average."* —
  double "yet", interval compared to a rule name, and the duration clause sits three
  lines beneath a visible 20:58 CHECK row it appears to contradict.
- **Mechanism:** template at TimerScreen partial-text builder; passes T0-14 because
  the malformed string is the template.
- **Disposition:** SP-194, decision 0022 §4. The dimension-naming template is
  retired. `TimerScreen.partialLine` returns the printed line and its spoken form
  together so the two cannot drift, in four shapes:
  1. both averages — *"Not at 5-1-1 yet — averaging 4:50 apart and 1:02 long over 8
     timed contractions."*
  2. interval only — *"Not at 5-1-1 yet — averaging 17:47 apart over 4 timed
     contractions; not enough finished ones yet to average their length."*
  3. no averages, contraction running — *"Timing this contraction — 5 in the last
     hour."* / *"Timing this contraction — nothing else in the last hour."*
  4. no averages, nothing running — *"Last contraction 47 M ago — not enough in the
     last hour to average."* (under a minute: "under a minute ago", never "0 M").

  Confirmed on glass at `dark-axl/classic-nullipara-typical--one-short-of-floor`
  (shape 1) and `light-m/multi-day-latent-exhausted--stale` (shape 3).

### F-0022 · S1 · design-gap · fixed(20260816T192715Z) — final semantics per 0026.2
- **Observed:** the tick tape (`min(patternLength/3600, 1)`) is full at 17:47
  spacing, full during met and not-met alike, full for the last 12 hours of any
  labor; no on-screen caption; it is the visual assertion of lull-ripenable
  sustainment.
- **Disposition (interim, wave 1 — decision 0022 §6):** once `patternLength ≥ 1 h` the
  tape stopped rendering and yielded the space rather than asserting a live progress
  that had stopped being live at the hour.
- **Disposition (final, wave C — decision 0026 §2):** the tape renders sustained
  *evidence*, not elapsed time: `LaborPattern.sustainedEvidence` is the time since the
  later of the episode's start and the newest continuity break inside the window,
  capped at the hour, and the fill is that over the rule's hour. A lull visibly empties
  it. **The interim yield is withdrawn** — the tape is back on screen past the hour,
  and it has earned that space, because a bar at full is now a claim the next quiet
  half hour will take back rather than a frozen 100 %. Its accessibility label moved
  with its meaning ("unbroken pattern toward one hour"), named once so the resting and
  live instruments cannot say different things. `sustainedEvidence` is compared against
  `LaborOracle` at every probe (T0-02), so the instrument and the boolean beneath it
  cannot drift apart.
- **One seam, on the record:** a break whose later contraction sits exactly on the
  window edge reads a full hour of evidence while `sustainedMet` is false — the
  dimension asks whether a break is *in* the window, the figure asks how long *since*
  one. It lasts a single second (the next tick carries that contraction out of the
  window) and it errs toward the tape claiming more than the verdict, never less.

### F-0026 · S1 · bug · fixed(20260816T175940Z) (new — Layer J)
- **Observed:** `kill-mid-contraction--after-kill`: first contraction renders
  `— / — / 0 M` — the zero-as-measurement T0-11 exists to forbid, passing on a
  technicality (patternLength has no floor).
- **Disposition:** SP-194, decision 0022 §7 — the PATTERN slot withholds below one
  minute (em dash, and the same "not enough contractions yet" VoiceOver value every
  other withheld slot uses). `SnapshotExportTests.ExpectedFacts` mirrors the
  withhold, so the index and the glass agree about what should be on screen.
  The same floor governs the header's "LAST {n} AGO" and the prose gap, which reads
  "under a minute" rather than "0 M" — prose can say what a data slot cannot.

### F-0027 · S2 · design-gap · open (new — fix wave C)
- **Observed:** the W2 harness scenario, re-measured after decision 0024 landed:
  `frequencyMet` is still **true** and `metrics.falseMetTicks > 0` on a body whose true
  mean start-to-start is 330 s. At a probe deep into the scenario `intervalRange` reads
  (150 s, 255 s) over 17 in-window intervals — a 100 % share.
- **Mechanism, and why 0024 does not reach it.** Decision 0024 addresses a coupled
  pattern *recorded faithfully*: alternating short and long gaps, where the mean is a
  value that never occurs. That case is closed (F-0008). This scenario models something
  else — a thumb tapping the phantom tightening a coupled trough produces, which is
  what coupling feels like. The extra tap does not shift an average toward the
  threshold; it **eliminates the long interval from the recorded stream entirely**,
  splitting every ~510 s trough into two ~255 s halves. No statistic over the recorded
  gaps can see a gap that is no longer in them. This is a recording-fidelity failure of
  the W7 family, not a statistic-choice gap, and it was mis-attributed to the mean in
  the first run's triage.
- **Disposition:** decision-needed. Candidate directions, none cheap: duration-aware
  interval weighting (a 70 s "contraction" mid-trough is not the same event as an 80 s
  one), or an explicit correction affordance for the tap the user did not mean. Both
  are verdict math and both need a decision first. Ranked S2 (false met) with low
  corpus prevalence — zero sampled coupling scenarios false-fired in the first run;
  it is validated by the seeded test only, which is F-0024's gap as much as this one's.
- **Independently reached twice.** The subagent flipping the W-tests measured this and
  refused to force the assertion the wave plan expected; the wave's own pin scaffolding
  had separately concluded that the harness scenario was not what 0024 closed and minted
  F-0008's pin from the textbook form instead. Recorded because a finding two passes
  reach from opposite directions is worth more than either pass's confidence in it.

## Harness findings

### F-0028 · harness · open (new — fix wave C) — **T1-02 cannot referee this wave**
- **Observed (20260816T192715Z):** false-met scenarios rose **2 → 18**, which is the one T1
  threshold this wave was supposed to hold flat. Instrumented at each scenario's first
  offending tick, by which of truth's four `mustNotFire` clauses is doing the
  condemning:

  | Truth's clause | Scenarios | Reading |
  |---|---|---|
  | `trueMeanInterval ≥ threshold + 15 s` | 12 | Truth judging by the **mean decision 0024 deliberately replaced** |
  | `trueMeanDuration ≤ 55 s` | 4 | Decision 0023's priced cost, now visible |
  | `count < 5` | 2 | Recording fidelity (phantom taps), pre-existing |

- **The 12.** Eleven of them are `irregularProgressing` (one `inductionRamp`) with true
  mean intervals of 316–369 s and recorded in-window ranges like 119–606 s and
  194–576 s. That is precisely the shape decision 0024 §1 says *should* now fire — "an
  irregular-but-progressing labor whose spacing has genuinely tightened passes as soon
  as most of its gaps have". `TruthCompiler` still asks whether the **mean** of the
  true stream clears the threshold, so a scenario the app now passes on a share is
  condemned by a referee still holding the old statistic. **This is F-0014 arriving:**
  T1-02 is not measuring a regression here, it is measuring the gap between two
  statistics, and it will keep doing so until truth gets an engine-independent one.
  The count is reported rather than explained away because the alternative — tuning
  2/3 until the old referee goes quiet — would be fitting the product to a known-stale
  oracle.
- **The 4** (recorded duration means 50.0, 53, 54, 54) are the honest edge of decision
  0023: truth's `mustNotFireDurationSeconds` is 55 s, chosen to straddle the *stated*
  60 s rule, and the evidence threshold at 50 s now sits **below** it. Where the old
  threshold cleared truth's ceiling by 5 s, the new one undercuts it by 5 s, so any
  faithful thumb on a true 50–55 s pattern reads as a false met. 0023 §1 argued the
  band would be protected by start latency; the `clean` and `partnerDiligent` profiles
  have little or none, and three of these four are exactly those profiles. One is
  `boundaryBattery-zeroLengthContraction`, a probe authored against the 60 s boundary
  that now sits exactly on the 50 s one — a corpus artifact, not a labor.
- **Three of the eighteen are latch-only** (raw not met at the same tick): decision
  0025 holding a verdict ten minutes into a `mustNotFire` zone. All three are in the
  `trueMeanInterval` group, so they are the same statistic gap arriving through the
  latch rather than a separate defect. That is the alarm-side asymmetry 0025 chose on
  purpose, and it is small.
- **Disposition:** decision-needed, and it is F-0014's work rather than a new
  direction. Truth needs (a) an engine-independent frequency statistic so a share can
  be refereed at all, and (b) duration margins keyed to whatever threshold the boolean
  actually reads, not to the rule the copy quotes. Until then the T1-02 figure for this
  corpus is uninterpretable and must not be quoted as a regression count. **No verdict
  math was tuned in response to it** — decisions 0023 and 0024 bind, and amending
  either is a decision entry, not a wave's discretion.

### F-0014 · harness · open
- Truth compiler shares the engine's window/mean/floors; recorded==true ⟹ agreement
  by construction — statistic-choice gaps (F-0008/F-0010 pure forms) are invisible
  to T1, detectable only via hand-authored scenarios.
- **Disposition:** SP-194 harness — truth gets an engine-independent statistic
  (median + max-gap continuity).

### F-0018 · harness · open (new — Layer J)
- T1-01 flags positive lag only. The clean-thumb reference scenario fired **37.6 min
  before** truth (appFirstMet 39871 vs truthFirstMet 42245) with `flags: []`, and
  the gallery's control shot is that early verdict. Onset-lag p50 is negative in 6
  of 10 archetypes. Early fire is S2 by the ranking law and currently unmeasured.
- **Disposition:** SP-194 harness — symmetric threshold (flag < −15 min), plus a
  gray-zone-aware classification (early-in-gray is defensible; early-in-mustNotFire
  is T1-02's job).

### F-0019 · harness · open (new — Layer J)
- Both "multi-episode" promoted moments pinned `latestStart` at exactly −7200 s;
  DemoSeed seeds against launch-now, render lands ms later on the stale side — two
  gallery shots render the empty state their captions contradict. The corpus's 10 ms
  boundary-clearance rule covers values, not moments.
- **Disposition:** SP-194 harness — moment picker keeps ≥5 s clear of every derived
  boundary; re-shoot.

### F-0020 · harness · open (new — Layer J)
- `LaborSeedSnapshot` carries no rule; DemoSeed never sets one. The
  `rule-switch-four-one-one` shot shows a 5-1-1 chip over 4-1-1 facts. No app-pass
  evidence exists for any rule but the default — the same blind spot as F-0013.
- **Disposition:** SP-194 harness — snapshot format v2 gains `rule`; DemoSeed writes
  it to the persisted rule key; re-shoot.

### F-0023 · harness · open (new — Layer J)
- The shots stage never asserts `snapshots/index.json`'s expectedFacts against the
  accessibility tree; T2 produced no machine rows this run. F-0019/F-0020/F-0025
  went unnoticed by the machine and were caught only by Layer J.
- **Disposition:** SP-194 harness — labor-sim.sh gains an assertion pass (XCUITest
  or simctl accessibility dump) over expectedFacts before screenshotting.

### F-0024 · harness · open (new — Layer J)
- BoundaryBattery has no seeds for W1 (290/315 alternation), W2 (2/8 coupling mean),
  W4 (burst-lull-tap), W10 (lull lastInterval); those weaknesses are validated only
  by hand-authored test scenarios outside the corpus. T1-04's flag never fired
  corpus-wide (detection lives in the W1 test). The report lacks an
  expected-detection section. (The mutation matrix itself completed 6/6 after the
  report rendered — the committed report's appendix understates it.)
- **Disposition:** SP-194 harness — add the four boundary seeds (semver minor →
  corpus 1.1.0), add the expected-detection section, refresh the kill matrix.

### F-0025 · harness · open (new — Layer J)
- `inductionRamp+tachysystole` produces only 8 true contractions; the promoted
  "densest timeline" shot shows 2 rows against a caption promising four rows and
  two-digit ordinals. T2-03 (timeline cap) has zero gallery evidence.
- **Disposition:** SP-194 harness — fix the variant's floor-interval segment length
  (it should sustain 95–110 s spacing long enough to accumulate 30+), re-promote.

## Layer-J counter-caution (on the record)

The evidence floors are not the enemy: floor starvation p50 −235 min, max +4.8 min,
0/215 over threshold. Every S4 in this run traces to duration understatement
(F-0006), the lost-tap chain (F-0003), or their interaction — not to the evidence
requirement. Fixes that loosen floors would trade honesty for nothing.

### F-0029 · harness · fixing (wave D; Christian flagged directly 2026-08-16)
- **Observed:** `MomentScan.init` hand-rolled the analysis window as
  `2 × rule.sustainedWindow` — two hours where `PatternAnalysis` uses one — under a
  comment claiming engine parity. `Sample.inWindow` double-counted, so
  `oneShortOfFloor` (resolves on `inWindow == floor − 1`) and `peakEvidence` picked
  the wrong instants to photograph.
- **Mechanism:** a second definition of the analysis window living outside the
  engine — the exact single-definition failure `PatternAnalysis.interval(from:to:)`
  was created to end (SP-191), recurring in the harness.
- **Disposition:** fixed in wave D: the local `windowSeconds` is gone;
  `Sample.inWindow` and every resolver `holds` predicate read the engine's own
  `LaborPattern.inWindowCount`, so this file no longer carries any window
  definition. **Verification gate:** the grand final run must show
  `one-short-of-floor` and `peak-evidence` gallery shots matching their captions —
  checked by eye at the advisor gate and by the new F-0023 expectedFacts assertion
  stage. Related: F-0019 (boundary clearance), F-0023 (facts assertions), both
  landing in the same wave.

### F-0030 · harness · open (wave D close-out, run 20260817T135952Z)
- **Observed:** `SnapshotFactAssertionTests` had never executed. `labor-sim.sh`'s
  assert stage reported `Executed 0 tests` because the file was added without a
  subsequent `xcodegen generate`, so it was absent from the generated project — and
  `xcodebuild` printed `TEST SUCCEEDED` over it. The harness's own silent-no-op trap
  caught this correctly ("produced no summary line — it did not run to completion"),
  which is the one part of this that worked as designed.
- **After `xcodegen generate` it runs — and every fact misses.** Not a few: every
  column value, every detail, every tape reading, across all 24 snapshots.
  Wholesale failure of that shape is a checker or seeding fault, not 24 simultaneous
  product regressions; the checker does implement the printed→spoken conversion
  (`spokenFragments`), so the likeliest causes are the column lookup returning nil or
  the snapshot seed not landing. Not yet diagnosed.
- **Consequence for F-0023:** it stays **open**. The stage exists and now executes,
  but it has never once asserted successfully, so the gap F-0023 describes — the
  shots stage verifying nothing — is still real. F-0019 and F-0020 also stay open:
  both are proven only through this stage.
- **Root cause (SP-195 phase 4): the checker, in one line.** `XCUIApplication.debugDescription`
  prints accessibility **labels** quoted and in full, and accessibility **values**
  *unquoted and truncated to twenty characters*:

      Other, 0x…, {{20.0, 903.3}, …}, label: 'interval', value: average 4 minutes ...

  The checker scraped values with `value: '([^']*)'`, which cannot match an unquoted
  field. `columnValue` therefore returned nil for every column on every snapshot, and
  every fact quoting a figure failed — reported as *"no accessibility element labelled
  'interval' found in the tree"*, which is what made a single parsing fault look like
  24 simultaneous product regressions. Truncation makes it unfixable by regex besides:
  `average 4 minutes ...` cannot be compared against "4 minutes 36 seconds" however it
  is parsed. Measured: **115 of 187 asserted facts missed, on 24 of 24 snapshots**; the
  72 that passed were exactly the label-only checks (banner text, timeline row counts,
  partial-line prefixes), which the dump does render faithfully.
- **Fix.** Every figure now comes from a real `XCUIElement` query (`ScreenCapture`),
  which returns the untruncated accessibility value; the dump is kept only for label
  containment, guarded by a sentinel that fails the snapshot loudly if the `label: '`
  marker ever disappears. Four queries per snapshot, resolved once at capture.
- **Four more checker faults were hiding behind it**, unreachable while every value
  lookup already returned nil, and all four are now fixed and commented at the site:
  1. `spokenFragments` expected "0 minutes 50 seconds" for a sub-minute figure;
     `LaborFormat.spoken` says "50 seconds". Every sub-minute DURATION average — the
     common case, not the edge — would have missed.
  2. The same helper expected "76 minutes" for an `M:SS` token past the hour;
     `spoken` says "1 hours 16 minutes". `intervalRange`'s upper bound reads 76:21 on a
     stalled pattern.
  3. `prose reads "Last contraction ended 2 H ago."` was checked as a literal, but
     `TimerScreen.emptyStateCopy` overrides that Text's accessibility label with the
     spoken gap — the printed sentence is never in the tree.
  4. The partial line's "not enough in the last hour to average" was matched
     case-sensitively; the spoken form starts a new sentence and capitalises it, so
     that check could never have succeeded.
- **One tolerance was added, deliberately and narrowly.** `ExpectedFacts` computes its
  figures at the snapshot's exact instant; the app resolves every offset against
  `Date()` in `ContractionsApp.init` and renders a second or three later. Fixed-offset
  figures (interval and duration means) are immune, but anything of the form
  `now − something` — PATTERN's `patternLength`, the header's "LAST … AGO" — grows by
  that gap, and `LaborFormat.hoursMinutes` floors to the minute. Two of twenty-four
  snapshots sat within a few seconds of a boundary and rendered one minute high. The
  tolerance is **one minute and upward only**, because launch time only moves forward;
  a figure reading low, or two minutes high, is still a miss. Distinct from F-0019,
  which is about moments landing on *derived* boundaries — no moment picker can avoid
  this one.
- **Result:** 115 misses → 0. `SNAPSHOT ASSERTIONS: 24 snapshot(s), 188 fact(s)
  asserted, 24 skipped (not assertable), 0 snapshot(s) with a miss.` The 24 skips are
  the History facts, which describe a screen the snapshot does not photograph.
- **Consequence for F-0023:** the stage now asserts, so F-0023 can close on the next
  green full run. F-0019 and F-0020 become checkable for the first time.
- The standing lesson is now three-for-three in this harness: `xcodebuild` reporting
  success over zero executed tests has produced a false green in every UI stage it
  touches, and only an affirmative summary line has ever caught it. Both new bundles
  (`AccessibilityAuditTests`, `LayoutInvariantTests`) carry the same trap, and
  `scripts/labor-sim.sh`'s `a11y_leg` and `scripts/a11y-ax5.sh` both check an
  `Executed N tests` count with N > 0 **and** the size the runner reports.

### F-0031 · S1 · bug · fixed(SP-195 phase 4)
- **Observed:** `AccessibilityAuditTests`, `howItWorks` state at AX5, two categories on
  one element — `textClipped` ("Text of this SwiftUI.AccessibilityNode may be clipped
  at larger Dynamic Type sizes") and `dynamicType`, on `StaticText 'Start'` at a frame
  of exactly `{48, 48}`.
- **Mechanism:** `HowItWorksScreen.MiniCircle` is `Text("Start").dataText(.label)`
  inside `.frame(width: 48, height: 48)` — a fixed frame on a text container, which is
  the one layout rule CLAUDE.md names outright. At AX5 the `.caption2`-scaled word is
  wider than the box it is drawn in.
- **Disposition:** fixed. The stamp scales with its word: `@ScaledMetric(relativeTo:
  .caption2)` on the diameter, matching the style `.dataText(.label)` itself resolves
  to, plus `.fixedSize()` so the word takes its natural width rather than the circle's.
  Measured at AX5: the frame goes 48 → 177.3 pt and the `textClipped` finding is gone.
  The only genuine product defect the new gate found.

### F-0032 · tooling · **closed** — SP-195, decision 0058 (opened SP-195 phase 4) — **the `dynamicType` audit is reporting a false positive**
- **Observed (AX5, dark):** `performAccessibilityAudit`'s `dynamicType` category fires
  on four element classes, always with the same detail — *"User will not be able to
  change the font size of this SwiftUI.AccessibilityNode"*:
  the two toolbar links (see F-0033), `SectionHeader`'s "YOUR GUIDELINE",
  `HistoryScreen`'s section header and summary line, and `MiniCircle`'s "Start".
  Every one of the last four is `.dataText(.label)`.
- **Why it is a false positive, measured rather than argued.** Three independent proofs,
  in ascending order of how little room they leave:
  1. The same `MiniCircle` element the audit says cannot change font size renders at
     **48 × 48 pt at the default size and 177.3 × 177.3 pt at AX5** — a 3.7× scale
     driven entirely by the content-size setting (F-0031's fix; the audit still fires
     on it afterwards).
  2. `HistoryScreen`'s section header is 164 pt tall at AX5 — four wrapped lines of an
     11 pt-base role.
  3. **The decisive one.** The audit also flags `StaticText 'Tap when it begins'`, the
     disc's caption, which is `.font(.prose)` — i.e. plain `Font.body`. A stock system
     text style cannot be a non-scaling font, and the element measures 226 × 126 pt at
     AX5. Whatever the audit is detecting, it is not the font.
- **Three candidate causes were tested on the simulator and eliminated**, one build
  each, on `GuidanceScreen`'s "YOUR GUIDELINE":
  1. `.kerning(role.tracking)` — `.label` is the only role with non-zero tracking.
     Set to 0: finding unchanged.
  2. `.weight(role.weight)` applied on top of a text-style font. Removed: finding
     unchanged.
  3. `.accessibilityShowsLargeContentViewer()`, HIG's documented remedy for text that
     cannot scale. Added to `DataTextModifier` and to the toolbar links: finding
     unchanged.
  What is left is the node, not the font: every flagged element is a composed or
  UIKit-hosted `SwiftUI.AccessibilityNode` (a `.combine`d `SectionHeader`, a `List`
  cell, a toolbar item), and the timer's own `sectionLabelText()` header — a plain
  `Text` — is **not** flagged in any state.
- **Disposition:** decision-needed, and deliberately **not** suppressed. Per SP-195
  phase 4's brief the gate carries zero suppressions and no `accepted` set, so
  `ContractionsUITests/AccessibilityAuditTests` is **currently red on this finding
  alone**, and the CI leg (`scripts/a11y-ax5.sh`) will be red with it. Two ways out,
  both needing a decision rather than an agent's discretion: (a) a decision entry
  accepting the false positive with the 48 → 177.3 measurement as its evidence — the
  same shape as decision 0015's "Dynamic Type" acceptance in the suite app, but for a
  different reason; or (b) dropping `.dynamicType` from the gate's **named category
  list**, which is visible in the list the test prints on every run and is therefore
  not the invisible kind of suppression the brief was written against. Recorded here
  first so whichever is chosen is chosen on the evidence.

- **Re-measured and accepted 2026-09-05 (decision 0058).** The evidence above was
  gathered before decision 0036 replaced the disc with a slab, so its headline proof —
  a `MiniCircle` scaling 3.7× — is about a view that no longer exists. Re-run against
  today's tree by `HushlightUITests/DynamicTypeAuditDiagnostics`, iPhone 16 Pro on
  iOS 18.5, at both sizes:

  | Element | default | AX5 | growth |
  |---|---|---|---|
  | `SectionHeader` "YOUR GUIDELINE" | 362.0 × **25.8** | 362.0 × **60.5** | **2.34×** |
  | toolbar `History` button | **62.7** × 33.7 | **73.7** × 33.7 | 1.18× wide, height system-fixed |

  **Two element classes now, not four**, and both are exactly what this entry predicted:
  a `.accessibilityElement(children: .combine)`d `SectionHeader` and a UIKit-hosted
  toolbar item. The negative control holds — the timer's own plain-`Text` section label
  is flagged in no state. The audit says "user will not be able to change the font size"
  about an element that grows by a factor of 2.34 between the two runs.

  Neither is fixable in app code: `SectionHeader` combines deliberately so a ruled
  heading speaks as one phrase, and the toolbar is system chrome whose text growth Apple
  caps. **Excluded, not suppressed** — the category is not one of the questions the gate
  asks, so SP-195's "zero suppressions" holds literally, and the reason now lives in
  `baseAuditTypes` beside the line it justifies rather than only here.

### F-0033 · S0 · accepted-limitation · open (new — SP-195 phase 4)
- **Observed:** `dynamicType` on `Button 'History'` and `Button 'Guidance'` — the two
  `NavigationLink`s in `TimerScreen`'s toolbar — in every one of the four timer states,
  at rest and scrolled. Frames 77.7 × 36 and 101.7 × 36 at AX5: the navigation bar does
  not grow.
- **Mechanism:** iOS does not scale navigation-bar button titles with Dynamic Type;
  the platform's answer is the Large Content Viewer on long press. `.accessibilityShowsLargeContentViewer()`
  was added to both links as an experiment and did not clear the finding (F-0032's
  third elimination).
- **Disposition:** this is system navigation furniture, and CLAUDE.md forbids
  rebuilding what the system provides — tab bar, navigation, sheets, status bar. There
  is no fix here that is not a hand-rolled navigation bar. Filed as an
  accepted-limitation pending the same decision F-0032 needs; the two travel together
  because they are the same audit category on the same run.

### F-0034 · design-gap · open (new — SP-195 phase 4) — **untriaged, and it needs a wave of its own**
- **Observed:** run `20260817T161038Z`, `a11y/default.log` — the **light + `large`** leg,
  the one that owns contrast. **38 `contrast` findings** across the seven states, the
  large majority "Contrast failed" rather than "nearly passed". Distinct elements:
  the two toolbar links; the disc's "Start" and "Tap when it begins" (white on the
  darkened blue gradient); the guideline chip "5-1-1 ›"; `SectionHeader`'s "Your
  guideline"; `GuidanceScreen`'s explanatory paragraph; `MiniCircle`'s "Start"; plus
  several the audit could only report as "unknown element".
- **Why it is unresolved rather than dispositioned.** This is the **first run of this
  gate against this app** — there is no previous result to compare against, so none of
  these are regressions and none can be assumed pre-existing either. Some are prima
  facie surprising: SP-195 phase 2 measured white-on-gradient at 5.00:1 in light, and
  phase 1 measured `secondaryText` at 5.88:1, both against the resolved system blue
  and the resolved screen background. The audit samples what is actually composited,
  including the halo and the `.bar` material, which is not the same measurement.
  Deciding which of the 38 are real needs per-element sampling, and doing that badly —
  by re-tuning a palette against an audit nobody has validated — is how a colour system
  gets wrecked. F-0032 is the standing warning: this same audit is demonstrably wrong
  about `Font.body`.
- **Disposition:** filed for a triage wave. The AX5 leg deliberately does not run
  contrast (nothing on that screen is under 18 pt, so it could only re-judge a subset
  against the easier large-text bar), so this list is complete as it stands: 38 at
  default size, zero at AX5.

- **Triage (2026-08-24, HL-019, decision 0044).** The list above no longer matches
  the app — it was measured pre-rebrand, and HL-001/HL-003 rebuilt every surface it
  names. A fresh run against today's code reports **66** `contrast` findings, not
  38, over different elements. Every *named* one (a real element, not `unknown
  element`) was checked against actual rendered pixels — `simctl io screenshot`,
  cropped to the element's own reported frame, measured with `PaletteContrastTests`'s
  own WCAG math:
  - **Four real, fixed.** `Palette.secondaryText`, `tint`, and `easing` are
    documented and tested only against `Palette.screen`; four call sites draw one
    of them on `Palette.inputFill` instead (Guidance's "Call right away" header,
    History's episode-summary line, History's trend caption, the slip strip's
    sentence) — 4.42:1 / 3.74:1 / 4.15:1 in light appearance, under AA. Two new
    tokens (`secondaryTextOnFill`, `easingText`) plus a third documented surface
    for the existing `tintText`; see decision 0044.
  - **Nine named, pixel-disproven.** Both toolbar links (measured **18.0:1** —
    the audit is checking the declared tint, not what iOS 27's Liquid Glass
    chrome actually paints, the same "not the composited pixel" verdict F-0032
    reached about `.dynamicType`), the slab's "Start" at both sizes (**6.1–6.9:1**,
    `onEmber` on the documented `emberSlab` stops), and the How It Works
    miniature's "5-1-1 ›" chip and "Your guideline" heading (**14.1:1**,
    `primaryText` on `screen`). All comfortably clear AA; the audit's claim does
    not survive contact with the actual pixels.
  - **The residue — every `unknown element` finding — is filed separately as
    F-0038.** It resists the same technique (no frame to screenshot) and a
    targeted elimination test, so it is not folded into either bucket above.

### F-0036 · design-gap · fixed(incidental, decision 0038) — **the light leg fails on more than contrast**

- **Observed:** the **light + `large`** leg of `scripts/labor-sim.sh`'s accessibility
  gate, on `main` (b5d86c3) with no HL work applied — so this is pre-existing and not a
  rebrand regression. Beyond F-0034's contrast list, **7 `elementDetection` findings**:
  3 on `met/scrolled`, 3 on `met/call/scrolled`, 1 on `partial/scrolled`. Every one
  reports `unknown element` — `issue.element` is nil, which is the audit saying no
  accessibility element exists over the text it detected.
- **Scale of the leg's failure, for the record.** Same run, per state:
  `met` 14, `met/scrolled` 20, `met/call` 18, `met/call/scrolled` 21, `partial` 9,
  `partial/scrolled` 13, `forgottenTimer` 8, `running` 5, `slip` 9, `howItWorks` 4.
  Only `history`, `history/scrolled` and `guidance` are clean. The AX5 leg is
  **0 findings across all twenty states**, so this is specific to default type, light
  appearance, and the categories only that size enables.
- **The obvious suspect is exonerated.** `EpisodeTimeline`'s connector row prints
  `"N:NN apart"` inside an `HStack` marked `.accessibilityHidden(true)`, which is
  exactly the shape `elementDetection` exists to catch, and `met` renders three of them
  against three findings. Tested directly: removing that `.accessibilityHidden(true)`
  left the elementDetection count **unchanged at 3** and raised the state's total from
  14 to 16 (the newly-exposed row bringing its own problems). The connector is not the
  cause, and the 3:3 match is a coincidence. Whatever the audit is seeing has no
  element at all — the same `unknown element` signature F-0034 already noted on
  "several" of its contrast findings, which suggests one underlying cause behind both
  halves of this leg rather than two.
- **Why it is filed rather than fixed.** F-0034's reasoning applies unchanged and is
  the governing warning: this gate has never been triaged against this app, F-0032 is
  standing proof that it is demonstrably wrong about `Font.body`, and chasing an
  `unknown element` finding without first establishing *which pixels* it is pointing at
  is how a colour system or an accessibility tree gets wrecked to satisfy a tool nobody
  has validated. Triage needs the screenshot-plus-tree diff that identified the
  `liveHero` finding (decision 0038) — the one technique that has actually located one
  of these.
- **Disposition:** filed to HL-019 with F-0034, which is the wave that owns this leg.

- **Triage (2026-08-24, HL-019, decision 0044).** `elementDetection` reads **zero
  across all twenty audited states**, in two independent full re-runs of this same
  leg against today's code. This finding closes incidentally rather than by a fix
  aimed at it: decision 0038 (`liveHero` speaking for itself, the tape's end caps
  moved out of the combined element) landed after this was measured on b5d86c3 and
  evidently accounts for the whole list. The `unknown element` signature this entry
  noted did not carry over to a cause, though — a *new* category, `hitRegion`,
  appears in this leg for the first time, at the same "no debugDescription" shape.
  Filed separately as F-0038 rather than folded in here, since it is a different
  audit category than the one this entry's title names.

### F-0035 · S4 · design-gap · fixed(SP-203, decision 0032, run `20260824T012847Z`)
- **Observed:** not by the harness, by the A1.2 walkthrough — a double tap on the disc
  recorded an 11-second "contraction" and the app said nothing about it. The corpus had
  been generating the same event all along and calling it a contraction: `pPhantom`
  drops a 2–10 s start/stop pair into dead time on 0.5–8 % of contractions by profile,
  and every one of them entered the duration mean.
- **Mechanism:** `Contraction.isSuspect` was one-sided. A record over three minutes was
  a forgotten stop-tap — flagged, excluded from the duration mean, its start still
  spacing the intervals. Nothing looked at the other end, so a few seconds of thumb
  bounce entered the exact average `durationMet` reads, in the direction that
  *suppresses* a verdict. Twelve believable 52-second contractions plus one 11-second
  slip average 48.8 s against a 50 s threshold: the verdict the body had earned goes
  quiet because a thumb bounced. Same shape as F-0007, opposite sign.
- **Disposition:** fixed. Decision 0032 gives the predicate a short side at 20 s, both
  bounds strict, treated exactly as the long side is — flagged `CHECK · UNDER 20 S`,
  out of the duration mean, start still counted, never auto-deleted. Only the long side
  keeps decision 0023 §2's floor relief: a forgotten stop-tap is evidence a contraction
  happened, a slip is evidence of nothing. Measured on corpus 2.0.0: suppressions
  46 → 41, false-met scenarios 40 → 42 — the S4-over-S2 trade the ranking law asks for.
  T0 stayed 413/413 clean, so the engine and `LaborOracle` moved together. Pinned by
  `F-0035.json`; the timer also offers the correction at the moment of the tap (SP-203's
  slip strip) rather than leaving it to be found in History.

### F-0059 · S3 · tooling · open (found running the AX5 gate on an iPad for HL-058a)

`HUSHLIGHT_A11Y_DEVICE_TYPE=…iPad-Air-11-inch-M3 ./scripts/a11y-ax5.sh` fails four audits with
`Text clipped — unknown element`: `testForgottenTimerIsAccessible` (18), `testGuidanceIsAccessible`
(3), `testHistoryIsAccessible` (1), `testCallButtonIsAccessibleWhereverItAppears` (2). The
same two screens pass on an iPhone 17 Pro at the same content size (0 findings), so it is
iPad-specific; History and Guidance changed by one prose sentence on Guidance. A bisect with
the ledger disabled cleared the running-state screen entirely and *raised* the other three to
40 findings between them — counts that move on unchanged screens. `issue.element` is nil in
every case, so nothing can be traced to a view; screenshots at AX5 (dark, portrait) show every
text whole, rows stacked as the accessibility branch requires. Not suppressed: the gate's
zero-suppression policy stands, and this is filed as what it is — a leg of the gate that does
not yet produce an actionable result on this device. Next: an attribution pass (frames from
`app.descendants` at audit time) on an iPad, and a check on whether iPadOS 26's window chrome
is inside the audited hierarchy.

### F-0060 · S2 · bug · fixed — HL-063 (found photographing the island on the iPhone Duo simulator)

`IslandTests` starts a contraction and leaves for the Home Screen on the iPhone Duo simulator
(iOS 27.1, outer display). The island there is vertical, down the trailing edge, and the
Live Activity's compact trailing slot — `Text(timerInterval:)` capped at 44 pt for the
horizontal island — broke the count across two lines: `0:0` over `4`. Every glyph present,
in the wrong order: the reflow class F-0055 and F-0056 named, on a surface no AX5 audit
reaches because SpringBoard draws it.

Three attempts, each photographed. `lineLimit(1)` + `minimumScaleFactor(0.5)`: still
wrapped — the system timer text ignores a scale factor in a Live Activity. Dropping the
44 pt cap and the hours digit (`showsHours: false`) plus a 2 pt compact-trailing margin:
one line, but the leading `0` sat under the island's curved edge — the timer reserves
the width of its longest value (`479:59`) and sets the digits at its trailing end.
Centring the text inside that reserve (`multilineTextAlignment(.center)`): `0:04` whole,
on one line, inside the island. The counts keep `lineLimit(1)` as a backstop. Known
edge: past ten minutes the figure grows to five glyphs; a contraction running that long
is already flagged CHECK at three. Severity S2 rather than S1: the expanded island and
the Lock Screen always carried the figure whole.

### F-0061 · S3 · tooling · open — HL-067 (found running the UI suite on the iPhone Duo for HL-060–065)

The full `HushlightUITests` run on the iPhone Duo simulator (iOS 27.1, closed, outer
display) fails 14 tests, and a control run of `origin/main` on the same simulator fails
the same 14 (plus `testForgottenTimerIsAccessible`): `ContractionMechanicsTests.testUndoOfEndResumesRunningContraction`,
`HandoffFallbackTests.testGuidanceCallPairKeepsItsFallbackAndMailShowsTheAddress`,
`SmallTargetDiagnostics.testSmallTargetsInHistory` and two audits stop at "Guidance never
pushed" / "no Back button" — each looks for the back button through
`app.navigationBars.buttons`, and on the 27.1 SDK the bars sit vertically at the edge;
nine `AccessibilityAuditTests` report contrast failures (and some clipping) on every
screen; `LocaleFormatUITests.testTapeEndCapsHoldTheirAxisUnderForcedRTL` never finds the
tape's end caps. Not caused by this branch; not yet known to be the app rather than the
harness. `LayoutInvariantTests` also failed there, but only because they need the host to
set AX5 first (`a11y-ax5.sh` does). Next: a screenshot of each failing state, then either
device-neutral lookups or a real fix.

**Not Duo-only.** A second control pair on an iPhone 17 Pro (iOS 27.0 release runtime):
`origin/main` and this branch fail the identical twelve — the ten audits,
`HandoffFallbackTests.testRefusedCallShowsTheNumberAndCopies` and the RTL tape caps. The
audits and the RTL test are therefore an iOS 27 runtime matter (the suite last ran green
on 26-era simulators); only the three back-button lookups are the Duo's. Separately, the
iOS 27.0 *beta* runtime (24A5380i) still installed here crashes the test runner while
bootstrapping and should be deleted.

### F-0062 · S3 · tooling · open — unfiled (found running the harness for HL-069's audit)

`scripts/newest-sim.sh iPhone` returns the newest runtime's first iPhone, and on a
machine whose newest runtime is iOS 27.1 that is the iPhone Duo. `simctl io <udid>
screenshot` exits nonzero on a device with two displays ("Cannot choose between 2
displays") unless `--display` is passed; `labor-sim.sh` swallowed the error per shot,
counted none, printed "0 shots" and carried on to a fact assertion that still passed —
it reads the app, not the pictures. The run looked whole and had no photographs in it.

**Fixed in HL-069:** a shots stage that takes no shot fails, and says to set
`HUSHLIGHT_SIM` to a single-display iPhone. Two neighbours fixed in the same pass: a red
engine leg did not fail the run (it does now), and the tick-tape fact compared a percent
against a value the tape has spoken as a count since decision 0037 §7, so it was
skipped as unparseable on every snapshot.

**Open:** the picker itself. `build.sh`, `test.sh`, `pseudo-check.sh` (which has the same
unguarded screenshot at line 117) and `walk-gates.sh` choose the same device. Either
the picker excludes the Duo unless asked, or the screenshot calls name a display.
