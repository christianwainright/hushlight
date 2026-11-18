# QA rubric — contraction timer (LaborKit / Contractions)

The evaluation rubric for the labor-sim QA harness (decision 0021, SP-193). Check
IDs are stable forever — findings and regression pins reference them.

## 1 · Layers and vocabulary

- **Layer E — engine replay.** Pure calls to `PatternAnalysis.pattern(for:rule:now:)`,
  `episodes(_:)`, `summary(of:)`, plus store-op replay against an in-memory
  `ModelContainer` and model-op replay against `LaborModel`. Runs the full corpus.
  Evaluation grid: every event time (tap/delete/undo/kill) ±1 s, every truth-zone
  boundary ±1 s, every derived knife-edge (window entry/exit, gap expiry), plus
  every 60 s of simulated time. Boundary probes carry the precision; the periodic
  grid carries coverage. All lag thresholds are stated in minutes so the grid never
  decides a verdict.
- **Layer A — app pass.** Sampled scenarios seeded into the simulator via
  `-laborScenario`, asserted primarily via the accessibility tree (text + geometry),
  screenshots for the gallery and for J.
- **Layer J — judgment review.** An agent answers a fixed questionnaire (§2, T3)
  over the scenario's truth timeline, engine tick trace, and screenshots. Produces
  findings, never pass/fail.

**Oracle independence rule:** every Layer-E expected value comes from `LaborOracle`,
which imports nothing from LaborKit. Booleans, partitions, counts, and nil-ness are
compared exactly; time figures within 0.5 s (plain-mean float drift), exact on the
boundary battery (whole-second inputs, integer-exact means). Corpus discipline: no
generated value may sit within 10 ms of a decision boundary unless the scenario is
an explicit boundary probe, and boundary probes use whole-second timestamps.

## 2 · The rubric

Format: **ID · owner layer · check.**

### T0 — Invariants. Binary. Any failure on any scenario is a red run.

| ID | Layer | Check |
|---|---|---|
| T0-01 | E+A | **No crash.** Engine replay completes without a throw on every scenario; app pass produces no crash log, no hang > 5 s. |
| T0-02 | E | **Oracle agreement.** Every derived figure — episode partition, `episodeStart`, `patternLength`, `lastInterval`, `averageInterval`, `averageDuration`, each guideline boolean, `met`, and all `EpisodeSummary` fields — equals the independent oracle at every grid point. |
| T0-03 | E | **Floors, both directions.** (a) figure non-nil ⟹ its floor is met; (b) figure nil ⟹ its floor is genuinely unmet — a nil above the floor is a *suppressed* figure and fails at S4. Same for `guideline`. |
| T0-04 | E | **Verdict never true below evidence.** `met == true` ⟹ all three dimensions true, ≥6 in window, both averages non-nil. |
| T0-05 | E | **Monotonic re-derivation.** `pattern(records, rule, now)` identical across repeated calls, input-order shuffles, and a store serialization round-trip. |
| T0-06 | E | **Episode split exactness.** Split iff start-to-start gap strictly > 2 h; exactly 2 h stays one episode. Probe both sides. |
| T0-07 | E | **Suspect iff duration > 180 s or < 20 s** (decision 0032). 180 s and 20 s exactly are not suspect. Suspect excluded from duration averages only; its start still counts for intervals and the floor count. |
| T0-08 | E | **end ≥ start always.** After any op sequence, including an end tap timestamped before its start (clock skew), stored `endedAt ≥ startedAt`. |
| T0-09 | E+A | **Kill/relaunch loses nothing.** Kill events → fresh context on the same container: running contraction survives with same id and start; full pattern identical to the no-kill control. App pass samples this on a real relaunch. |
| T0-10 | E | **Correction round-trips.** delete→restore yields an id-identical record set and identical pattern; begin-while-running is a no-op returning the running record; end-while-none records nothing; at most one running contraction ever exists. |
| T0-11 | A | **Em dash, never zero, below floors.** No figure slot renders `0`, `0:00`, `0 M`, or VoiceOver "zero" while its floor is unmet. |
| T0-12 | A | **Floors apply to derived figures only.** Every episode record renders a raw timeline row — all in History, the newest ≤4 on the timer — regardless of floors. |
| T0-13 | E | **Stale episode reads empty.** `now − latest start > 2 h` ⟹ `.empty`, at exactly the boundary tick. |
| T0-14 | A | **Copy invariants.** Rendered verdict text matches the shipped templates exactly. Banned-phrase regex over all rendered text (case-insensitive): `you( a\|')re in labor`, `don'?t need to go`, `you must`, `go to the hospital now`. The list is explicit and short; tone beyond it is T3's job. |
| T0-15 | A | **Suspect renders in words.** "CHECK · OVER 3 MIN" or "CHECK · UNDER 20 S"; no orange anywhere in this app. |

### T1 — Verdict quality vs the clinical-intent oracle. Measured, thresholded.

Truth is computed from what the body did (the noise-free stream), not what the taps
recorded — the gap between them is exactly what T1 measures.

| ID | Metric | Definition | Flag threshold |
|---|---|---|---|
| T1-01 | **Onset lag** | `t(first app met) − t(first truth met)` per scenario | > 10 min clean; > 20 min under any single-noise profile |
| T1-02 | **False met** | Any grid tick with `met == true` while truth is mustNotFire | any occurrence |
| T1-03 | **Suppression** | Truth met and stays met ≥ 30 min, app never fires | any occurrence — S4, outranks all lag |
| T1-04 | **Flap count** | `met: true→false` transitions while truth stays met; plus banner churn (none/partial/met transitions) per hour — each met flip implies a screen reorder today | > 2 flaps in any 30-min truth-met span, or churn > 6/h |
| T1-05 | **Noise delta** | Paired same-seed runs: clean vs suspect1 / missed{k} / mistap / undo-cycle / kill / clockskew; Δ onset lag, Δ flaps | one suspect or one miss shifting onset > 15 min, or suppressing outright |
| T1-06 | **Floor starvation** | `t(floors first satisfied) − t(truth met)` — the floors' cost, measured so the trade is visible | > 30 min |

### T2 — Presentation under scenario.

| ID | Layer | Check |
|---|---|---|
| T2-01 | A | **Parse-back formatting.** Every rendered figure parses back to the oracle value under the format grammar (62 s → "1:02"; ≥60 min in hours-minutes). Parse-back equality, not string pinning. |
| T2-02 | A | **Interval-connector pairing.** Each interval renders on the connector between exactly the pair it measures and equals the oracle value for that pair. |
| T2-03 | A | **Timeline cap.** 50-contraction episode: timer shows exactly the 4 newest rows; History shows all 50; ordinals are per-episode. |
| T2-04 | A | **Dark + XL primary pass.** Nothing truncates; header and banner coexist; readout scrolls behind the button bar. Light + default type as the secondary sweep. |
| T2-05 | A | **The button.** ≥216 pt, frame origin identical across states, label is an action, never a state. |
| T2-06 | A | **Multi-day History.** Episode sections split at oracle boundaries; summary bands honor floors (span nil for a lone contraction — no "0 M"). |
| T2-07 | E+A | **Scale.** 500+ records: `pattern()` p99 < 50 ms (E microbenchmark); cold launch < 3 s, History scrolls without hang (A). |
| T2-08 | E | **Live Activity divergence sentinel.** Static assertions that (a) the intent's hard-coded `.fiveOneOne` is reconciled with the selectable rule or documented by decision, and (b) content state still carries no verdict. Exists to fail the moment either changes silently. |
| T2-09 | A | **Accessibility.** Every figure has label/value; VoiceOver on dash slots never reads a bare number; suspect row reads its words. |

### T3 — Judgment findings. Layer J. Never pass/fail.

Fixed questionnaire per sampled scenario (structured answers, comparable across runs):

1. At each screenshot moment, what would a first-time 3 am user most likely
   conclude? Is that supported by the truth timeline?
2. Is any figure technically correct but misleading here — window staleness after a
   burst, a coupling mean, a lull-ripened "sustained," whole-episode `lastInterval`
   beside windowed averages?
3. Does any transition (banner appear/vanish, reorder, figures dropping to dashes)
   contradict what just physically happened?
4. Does the copy read as alarm or false reassurance *in this specific state*?
5. Name the smallest change that would fix the worst of the above.

Standing T3 assignments: 3-day prodromal display; burst-ended-20-min-ago staleness;
coupling (alternating 2/8); DST/manual clock shift; the drive-to-hospital gap
(+30 min, +90 min, +121 min); lull-ripened sustainedMet; met-reorder at XL.

## 3 · Severity classes — the ranking law (decision 0021)

S4 suppressed legit verdict / wrong safety-path figure → S3 delayed verdict, hidden
data, stale masking → S2 false met / early fire / flapping → S1 wrong presentation
of correct values → S0 cosmetic. Ranking key: (class, magnitude, prevalence), desc.

## 4 · Pre-registered weaknesses (rubric validation seeds)

Each ships as a seeded corpus scenario annotated `expected_detection: [check ids]`;
the validation mode fails if any expected detection stays silent. Complemented by
engine mutations in a scratch worktree (gap `>`→`≥`; drop suspect exclusion; floor
6→2; window 1 h→2 h; sustained anchor episodeStart→latest start; mean→median) — each
mutant must kill ≥1 check. A check no seeded weakness and no mutant can trip is dead
weight: fix it or delete it.

| # | Predicted weakness | Mechanism | Must be caught by |
|---|---|---|---|
| W1 | Verdict flapping, reorder churn | No hysteresis; mean drifts across 300 s as old intervals age out; screen reorders per flip. Probe: 290/315 s alternation. | T1-04; T3-Q3 |
| W2 | Coupling defeats the mean | Alternating 2/8 min → mean exactly 5:00 → `frequencyMet`; truth: not met. | T1-02; T3-Q2 |
| W3 | Dropped interval at window edge | First in-window contraction's predecessor is out-of-window; its interval vanishes — averages biased, floors later than row count suggests. | T1-01/T1-06 |
| W4 | Lull-ripened sustainedMet | `patternLength = now − episodeStart`: six quick taps + 50-min lull + one tap → "sustained 1 h". | T1-02 burst-lull; T3-Q2 |
| W5 | Drive-gap cliff | Taps stop after met; window drains: verdict drops at inWindow<6, figures dash out, all vanish at exactly +2 h. Reads as the app losing her labor mid-drive. | T3 standing; T1 transition trace |
| W6 | One suspect nulls the verdict at floor edge | 6 in window, usable durations exactly 3; one forgotten stop → 2 usable → `averageDuration` nil → verdict nil. | T1-05 "suppresses outright" |
| W7 | Missed contractions inflate the mean | Untapped contractions lengthen recorded gaps; genuinely-met reads unmet. Quantify tolerated misses. | T1-05 missed{k}; T1-01 |
| W8 | Clock skew renders impossible figures | Future-dated start → negative `patternLength`/interval; store clamps end≥start, nothing clamps vs now. | T0-02; T0-11/T2-01; T3 DST |
| W9 | Live Activity rule divergence | Intent hard-codes `.fiveOneOne`; app rule selectable. Latent today, one refactor from a lock-screen contradiction. | T2-08 sentinel |
| W10 | lastInterval contradicts the windowed story | Whole-episode `lastInterval` can read 45 min beside a 4:50 windowed average. | T3-Q2 |

**The table is the pre-registration and stays as written** — it records what was
predicted before the corpus ran, and rewriting it after a fix would destroy the only
evidence that the prediction was made in advance. What moves is
`WeaknessDetectionTests`: a weakness the product no longer has flips to asserting
*non*-detection, with a line at the test naming the decision that closed it. As of fix
wave C (SP-194) that is **W1** (0024 removes the mean-drift mechanism; 0025 latches
what remains), **W2** (0024, the share), **W3**'s first half (0023 §3, the bridging
interval — the evidence-count cliff in its second half is untouched), **W4** (0026,
windowed continuity) and **W6** (0023 §2, suspect relief). W5, W7, W8, W9 and W10
stand. Each closed row has a regression pin under `docs/qa/corpus/pins/`.

## 5 · Classification and routing (summary; full law in decision 0021)

bug (T0 fail, or contradicts a decision/AC) → SP item directly, T0 jumps the queue.
design-gap (spec'd math misbehaves) → decision entry first, then SP item.
accepted-limitation → FINDINGS entry + decision ref + `expected` corpus annotation.
not-built (export/share, Watch, notifications, localization, iPad, network,
HealthKit, home widgets) → hard suppression filter; never filed.
