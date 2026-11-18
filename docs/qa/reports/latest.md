# Labor QA report — 20260817T135952Z

## Run summary

- Run dir: `20260817T135952Z`
- Git ref: `33a364e`
- Started at: 2026-08-17T13:59:58Z
- Corpus: generator `2.0.0`, digest `d913dccbe6b05bfe76ea0fe32499d00ba3b76d741b9433b4e54ef7ee9891af75`, size 413
- Corpus manifest: `docs/qa/corpus/manifest.json` states version `2.0.0` (digest matches this run).
- **Not comparable to corpus 1.0.0 runs** — this run's rows are corpus `2.0.0`; do not diff them against a 1.0.0-digest report (decision-record convention, RUBRIC's semver note in the manifest itself).
- Scenarios: 413 distinct ids, 545 scenario × leg rows
- Legs: agreement: 22, model: 55, pure: 413, store: 55
- Total probes evaluated (sum of probeCount across all rows): 373197
- Wall-clock duration: 0h 4m (started 2026-08-17T13:59:58Z, latest artifact 2026-08-17T14:04:09Z)
- Deep mode: false
- Stages recorded: 3

## T0 — invariant grid

| Archetype | clean | partnerDiligent | typicalSolo | exhaustedSolo | chaotic | clockHostile |
|---|---|---|---|---|---|---|
| classicNullipara | 5/5 | 5/5 | 8/8 | 6/6 | 3/3 | 3/3 |
| classicMultipara | 3/3 | 3/3 | 8/8 | 10/10 | 3/3 | 3/3 |
| precipitous | 3/3 | 3/3 | 6/6 | 6/6 | 5/5 | 5/5 |
| prodromalFizzle | 5/5 | 5/5 | 8/8 | 6/6 | 3/3 | 3/3 |
| prodromalNightly | 4/4 | 4/4 | 9/9 | 11/11 | 4/4 | 4/4 |
| braxtonHicks | 3/3 | 3/3 | 6/6 | 6/6 | 5/5 | 5/5 |
| irregularProgressing | 5/5 | 5/5 | 8/8 | 6/6 | 3/3 | 3/3 |
| backLaborCoupling | 3/3 | 3/3 | 8/8 | 10/10 | 3/3 | 3/3 |
| pretermEarly | 4/4 | 4/4 | 7/7 | 7/7 | 6/6 | 6/6 |
| inductionRamp | 6/6 | 6/6 | 9/9 | 7/7 | 4/4 | 4/4 |
| multiDayLatent | 4/4 | 4/4 | 9/9 | 11/11 | 4/4 | 4/4 |
| sromThenOnset | 3/3 | 3/3 | 6/6 | 6/6 | 3/3 | 3/3 |
| boundaryBattery | 41/41 | – | – | – | – | – |

### T0 check breakdown

no T0 violations recorded in this run.

## T1 — verdict quality

### Onset lag by archetype

| Archetype | n | p50 (min) | p90 (min) | p99 (min) | max (min) |
|---|---|---|---|---|---|
| classicNullipara | 24 | 0.5 | 90.1 | 98.5 | 98.5 |
| classicMultipara | 19 | 0.9 | 67.2 | 92.4 | 92.4 |
| precipitous | 18 | -5.7 | 54.1 | 54.2 | 54.2 |
| prodromalNightly | 4 | -9.3 | 28.2 | 28.2 | 28.2 |
| irregularProgressing | 19 | -4.6 | 108.2 | 113.4 | 113.4 |
| backLaborCoupling | 6 | -21.1 | 10.6 | 10.6 | 10.6 |
| inductionRamp | 9 | -10.0 | 71.0 | 71.0 | 71.0 |
| multiDayLatent | 26 | -3.7 | 71.7 | 98.7 | 98.7 |
| sromThenOnset | 12 | -9.9 | 25.4 | 54.0 | 54.0 |
| boundaryBattery | 2 | -15.0 | -15.0 | -15.0 | -15.0 |

### Early fire (T1-01's symmetric half, F-0018)

| Scenario | Leg | Archetype | Noise | Early by (min) | Graded |
|---|---|---|---|---|---|
| backLaborCoupling-v1-typicalSolo-r0-fiveOneOne-B350A55A3B3BF781 | pure | backLaborCoupling | typicalSolo | 83.3 | gray |
| multiDayLatent-v8-clockHostile-r0-fiveOneOne-8D2B72CF31040399 | pure | multiDayLatent | clockHostile | 69.2 | gray |
| classicNullipara-v0-clean-r0-threeOneOne-A1089CA3EE5B42C8 | pure | classicNullipara | clean | 56.6 | gray |
| multiDayLatent-v0-typicalSolo-r1-fiveOneOne-E337C175AA15ED14 | pure | multiDayLatent | typicalSolo | 49.5 | gray |
| multiDayLatent-v0-clean-r0-fiveOneOne-E337C175AA15ED14 | pure | multiDayLatent | clean | 44.6 | gray |
| classicNullipara-v2-clean-r0-fiveOneOne-DB13BB56EF39AC51 | pure | classicNullipara | clean | 44.0 | gray |
| multiDayLatent-v1-clockHostile-r0-fiveOneOne-2221C7179FBA33C4 | pure | multiDayLatent | clockHostile | 41.0 | gray |
| multiDayLatent-v3-clean-r0-fiveOneOne-0C4D0469D6431F2F | pure | multiDayLatent | clean | 39.5 | gray |
| multiDayLatent-v0-partnerDiligent-r0-fiveOneOne-E337C175AA15ED14 | pure | multiDayLatent | partnerDiligent | 38.8 | gray |
| multiDayLatent-v1-clean-r0-fiveOneOne-2221C7179FBA33C4 | pure | multiDayLatent | clean | 38.5 | gray |
| multiDayLatent-v1-partnerDiligent-r0-fiveOneOne-2221C7179FBA33C4 | pure | multiDayLatent | partnerDiligent | 38.4 | gray |
| irregularProgressing-v2-clean-r0-fiveOneOne-AA08785D2D603834 | pure | irregularProgressing | clean | 37.0 | gray |
| irregularProgressing-v2-partnerDiligent-r0-fiveOneOne-AA08785D2D603834 | pure | irregularProgressing | partnerDiligent | 37.0 | gray |
| prodromalNightly-v3-clean-r0-fiveOneOne-57970FFB0CEC0AFA | pure | prodromalNightly | clean | 35.7 | gray |
| classicNullipara-v0-clean-r0-fiveOneOne-A1089CA3EE5B42C8 | pure | classicNullipara | clean | 34.9 | gray |
| multiDayLatent-v0-typicalSolo-r0-fiveOneOne-E337C175AA15ED14 | pure | multiDayLatent | typicalSolo | 34.0 | gray |
| classicNullipara-v1-clockHostile-r0-fiveOneOne-D5A6A21B9EDE67EA | pure | classicNullipara | clockHostile | 32.9 | gray |
| classicMultipara-v1-partnerDiligent-r0-fiveOneOne-BECF03CAAB48DC22 | pure | classicMultipara | partnerDiligent | 32.4 | gray |
| classicNullipara-v1-clean-r0-fiveOneOne-D5A6A21B9EDE67EA | pure | classicNullipara | clean | 31.9 | gray |
| backLaborCoupling-v1-partnerDiligent-r0-fiveOneOne-B350A55A3B3BF781 | pure | backLaborCoupling | partnerDiligent | 28.4 | gray |
| irregularProgressing-v1-clockHostile-r0-fiveOneOne-D197A0E0E276E14E | pure | irregularProgressing | clockHostile | 27.0 | gray |
| classicMultipara-v1-clean-r0-fiveOneOne-BECF03CAAB48DC22 | pure | classicMultipara | clean | 26.6 | gray |
| classicNullipara-v1-partnerDiligent-r0-fiveOneOne-D5A6A21B9EDE67EA | pure | classicNullipara | partnerDiligent | 25.9 | gray |
| classicMultipara-v1-typicalSolo-r1-fiveOneOne-BECF03CAAB48DC22 | pure | classicMultipara | typicalSolo | 25.3 | gray |
| irregularProgressing-v1-clean-r0-fiveOneOne-D197A0E0E276E14E | pure | irregularProgressing | clean | 24.6 | gray |
| classicMultipara-v1-clockHostile-r0-fiveOneOne-BECF03CAAB48DC22 | pure | classicMultipara | clockHostile | 24.6 | gray |
| irregularProgressing-v1-typicalSolo-r1-fiveOneOne-D197A0E0E276E14E | pure | irregularProgressing | typicalSolo | 24.5 | gray |
| precipitous-v0-clean-r0-fiveOneOne-3133187D56041AAC | pure | precipitous | clean | 22.3 | gray |
| backLaborCoupling-v1-clockHostile-r0-fiveOneOne-B350A55A3B3BF781 | pure | backLaborCoupling | clockHostile | 21.1 | gray |
| multiDayLatent-v2-clean-r0-fiveOneOne-0EDFC2F93F7A7751 | pure | multiDayLatent | clean | 20.6 | gray |
| classicNullipara-v0-clean-r0-fourOneOne-A1089CA3EE5B42C8 | pure | classicNullipara | clean | 20.3 | gray |
| multiDayLatent-v2-typicalSolo-r0-fiveOneOne-0EDFC2F93F7A7751 | pure | multiDayLatent | typicalSolo | 20.2 | gray |
| sromThenOnset-v0-clean-r0-fiveOneOne-6F396A6EE5AF2A21 | pure | sromThenOnset | clean | 19.1 | gray |
| sromThenOnset-v0-partnerDiligent-r0-fiveOneOne-6F396A6EE5AF2A21 | pure | sromThenOnset | partnerDiligent | 19.0 | gray |
| precipitous-v1-clean-r0-fiveOneOne-C552CD8DEAB322FD | pure | precipitous | clean | 18.4 | gray |
| precipitous-v1-partnerDiligent-r0-fiveOneOne-C552CD8DEAB322FD | pure | precipitous | partnerDiligent | 18.4 | gray |
| multiDayLatent-v4-partnerDiligent-r0-fiveOneOne-052A8BB8CD575533 | pure | multiDayLatent | partnerDiligent | 15.8 | gray |
| inductionRamp-v1-typicalSolo-r1-fiveOneOne-4288B8CE7DAEA4E8 | pure | inductionRamp | typicalSolo | 15.6 | gray |
| precipitous-v0-partnerDiligent-r0-fiveOneOne-3133187D56041AAC | pure | precipitous | partnerDiligent | 15.5 | gray |
| inductionRamp-v1-clockHostile-r0-fiveOneOne-4288B8CE7DAEA4E8 | pure | inductionRamp | clockHostile | 15.5 | gray |
| classicMultipara-v0-partnerDiligent-r0-fiveOneOne-288268FB0D3C0260 | pure | classicMultipara | partnerDiligent | 15.4 | gray |
| irregularProgressing-v0-clockHostile-r0-fiveOneOne-548910ABF9362525 | pure | irregularProgressing | clockHostile | 15.4 | gray |

42 scenario(s) fired early; 0 landed in a `mustNotFire` zone (T1-01's early-fire flag) rather than gray.

### False-met scenarios

| Scenario | Leg | Archetype | Noise | Ticks | Seconds |
|---|---|---|---|---|---|
| irregularProgressing-v0-typicalSolo-r1-fiveOneOne-548910ABF9362525 | pure | irregularProgressing | typicalSolo | 35 | 855 |
| backLaborCoupling-v2-clean-r0-fiveOneOne-B06CCB321BFDE107 | pure | backLaborCoupling | clean | 20 | 555 |
| backLaborCoupling-v2-partnerDiligent-r0-fiveOneOne-B06CCB321BFDE107 | pure | backLaborCoupling | partnerDiligent | 16 | 501 |
| multiDayLatent-v0-typicalSolo-r1-threeOneOne-E337C175AA15ED14 | pure | multiDayLatent | typicalSolo | 18 | 489 |
| irregularProgressing-v0-clean-r0-fourOneOne-548910ABF9362525 | pure | irregularProgressing | clean | 13 | 479 |
| boundaryBattery-intervalExactly180 | pure | boundaryBattery | clean | 13 | 479 |
| classicMultipara-v1-exhaustedSolo-r0-threeOneOne-BECF03CAAB48DC22 | pure | classicMultipara | exhaustedSolo | 17 | 457 |
| boundaryBattery-intervalExactly240 | pure | boundaryBattery | clean | 10 | 419 |
| boundaryBattery-advClearAllMidEpisode | pure | boundaryBattery | clean | 13 | 400 |
| irregularProgressing-v2-typicalSolo-r1-fiveOneOne-AA08785D2D603834 | pure | irregularProgressing | typicalSolo | 16 | 358 |
| multiDayLatent-v1-exhaustedSolo-r0-threeOneOne-2221C7179FBA33C4 | pure | multiDayLatent | exhaustedSolo | 9 | 350 |
| boundaryBattery-oneSuspectAmongGood | pure | boundaryBattery | clean | 8 | 300 |
| boundaryBattery-intervalExactly300 | pure | boundaryBattery | clean | 8 | 300 |
| boundaryBattery-durationExactly180 | pure | boundaryBattery | clean | 8 | 300 |
| boundaryBattery-durationExactly61 | pure | boundaryBattery | clean | 8 | 300 |
| boundaryBattery-durationExactly59 | pure | boundaryBattery | clean | 8 | 300 |
| boundaryBattery-durationExactly60 | pure | boundaryBattery | clean | 8 | 300 |
| inductionRamp-v0-partnerDiligent-r0-fiveOneOne-6BAD21B7465A9A89 | pure | inductionRamp | partnerDiligent | 8 | 264 |
| inductionRamp-v0-clean-r0-fiveOneOne-6BAD21B7465A9A89 | pure | inductionRamp | clean | 6 | 263 |
| inductionRamp-v1-typicalSolo-r1-fiveOneOne-4288B8CE7DAEA4E8 | pure | inductionRamp | typicalSolo | 11 | 250 |

_+20 more not shown._

Latch-graced ticks (raw-false, latched-met inside a `mustNotFire` zone, exempted from the count above): 119.

### False-met clause attribution (F-0028)

not present in this run — `T1MetricSet` needs a `falseMetClause: String?` field (the `reason` of the `mustNotFire` `TruthZone` — `"count"`, `"sustained"`, `"frequency"` or `"duration"` — that condemns this scenario-leg's *first* false-met tick) for this table to attribute the 40 false-met scenario(s) above to a clause. F-0028 is explicit that the raw count is otherwise uninterpretable.

### Flap histogram

| Worst flaps in 30 min | Count |
|---|---|
| 0 | 370 |
| 1 | 40 |
| 2 | 2 |
| 3-5 | 1 |
| 6+ | 0 |

Banner churn per hour — p90: 1.5, max: 4.5 (n=413).

Flaps in mustFire zones — latched: 49, raw: 91, across 71 scenario(s) with any raw flap. The latch absorbed 42.

Flap destination split — met→noVerdict: 19, met→partial: 30 (sum 49 against a latched total of 49).

### Paired noise-delta

| Noise profile | n | median Δ onset (min) | max Δ onset (min) | suppressed-but-clean-didn't | median Δ flaps |
|---|---|---|---|---|---|
| partnerDiligent | 23 | 0.1 | 106.8 | 0 | 0 |
| typicalSolo | 41 | 20.7 | 138.0 | 0 | 0 |
| exhaustedSolo | 17 | 106.7 | 134.0 | 0 | 0 |
| chaotic | 3 | 25.6 | 102.4 | 0 | 1 |
| clockHostile | 21 | 26.0 | 116.3 | 0 | 0 |

### Suppression by noise profile

**Total suppressions in this run: 46** — S4, the top of the ranking law (decision 0021 §2).

| Noise profile | Suppressions |
|---|---|
| typicalSolo | 4 |
| exhaustedSolo | 23 |
| chaotic | 18 |
| clockHostile | 1 |

### Floor starvation

p50: -197.8 min, p90: -35.2 min, max: 11.4 min (n=194).

Over the 30 min T1-06 threshold: 0 of 194.

## Expected-detection validation (RUBRIC §4)

no scenario in this run carries `expectedDetection` — `ScenarioResult` needs an `expectedDetection: [String]?` field (mirroring `ScenarioManifest.expectedDetection`), threaded from `manifest.expectedDetection` at each `ScenarioResult(...)` construction site (`PureSweepTests.swift`, `ModelReplayTests.swift`, `StoreReplayTests.swift`, `LegAgreementTests.swift`) for this section to render anything.

## T2 — presentation and scale

no bench output in this run; T2-07 microbench lives in LaborSimTests/ScaleBenchTests.swift.

## Worst 12

| Rank | Sev | Scenario | Archetype | Noise | Metric | Flags |
|---|---|---|---|---|---|---|
| 1 | S4 | multiDayLatent-v7-chaotic-r0-fiveOneOne-9780B551631112F6.pure | multiDayLatent | chaotic | suppressed 141.3 min zone | T1-03, T1-05 |
| 2 | S4 | classicNullipara-v0-chaotic-r0-fiveOneOne-A1089CA3EE5B42C8.pure — [chaotic-forgotten-stop--suspect-present](shots/dark-axl/chaotic-forgotten-stop--suspect-present.png) | classicNullipara | chaotic | suppressed 135.2 min zone | T1-03, T1-05 |
| 3 | S4 | classicNullipara-v0-exhaustedSolo-r0-fiveOneOne-A1089CA3EE5B42C8.pure — [kill-mid-contraction--after-kill-mid-contraction](shots/dark-axl/kill-mid-contraction--after-kill-mid-contraction.png), [kill-mid-contraction--peak-evidence](shots/dark-axl/kill-mid-contraction--peak-evidence.png) | classicNullipara | exhaustedSolo | suppressed 135.2 min zone | T1-03, T1-05 |
| 4 | S4 | classicNullipara-v0-exhaustedSolo-r1-fiveOneOne-A1089CA3EE5B42C8.pure | classicNullipara | exhaustedSolo | suppressed 135.2 min zone | T1-03, T1-05 |
| 5 | S4 | multiDayLatent-v0-chaotic-r0-fiveOneOne-E337C175AA15ED14.pure | multiDayLatent | chaotic | suppressed 133.1 min zone | T1-03, T1-05 |
| 6 | S4 | multiDayLatent-v2-chaotic-r0-fiveOneOne-0EDFC2F93F7A7751.pure | multiDayLatent | chaotic | suppressed 125.5 min zone | T1-03, T1-05 |
| 7 | S4 | multiDayLatent-v2-exhaustedSolo-r1-fiveOneOne-0EDFC2F93F7A7751.pure | multiDayLatent | exhaustedSolo | suppressed 125.5 min zone | T1-03, T1-05 |
| 8 | S4 | prodromalNightly-v3-chaotic-r0-fiveOneOne-57970FFB0CEC0AFA.pure | prodromalNightly | chaotic | suppressed 121.6 min zone | T1-03, T1-05 |
| 9 | S4 | prodromalNightly-v3-exhaustedSolo-r0-fiveOneOne-57970FFB0CEC0AFA.pure | prodromalNightly | exhaustedSolo | suppressed 121.6 min zone | T1-03, T1-05 |
| 10 | S4 | classicMultipara-v2-exhaustedSolo-r1-fiveOneOne-8CEF4221BA9F2DE8.pure | classicMultipara | exhaustedSolo | suppressed 117.4 min zone | T1-03, T1-05 |
| 11 | S4 | classicNullipara-v1-chaotic-r0-fiveOneOne-D5A6A21B9EDE67EA.pure | classicNullipara | chaotic | suppressed 111.7 min zone | T1-03, T1-05 |
| 12 | S4 | classicNullipara-v2-chaotic-r0-fiveOneOne-DB13BB56EF39AC51.pure | classicNullipara | chaotic | suppressed 101.8 min zone | T1-03, T1-05 |

## Findings delta

### Status counts

| Severity | Count |
|---|---|
| S1 | 6 |
| S2 | 4 |
| S3 | 7 |
| S4 | 3 |
| — | 9 |

| Status | Count |
|---|---|
| bug | 8 |
| design-gap | 12 |
| harness | 9 |

### Registered vs. FINDINGS.md

- Registered `knownRef`s in this run with no row in FINDINGS.md: none.
- FINDINGS.md rows with no matching `knownRef` in this run: F-0001, F-0002, F-0003, F-0004, F-0005, F-0006, F-0007, F-0008, F-0009, F-0010, +19 more.

## Appendix: kill matrix

| Source | Mutant | Verdict | Killed by |
|---|---|---|---|
| inplace-matrix | gapWiden | KILLED | everyScenarioAgreesWithTheOracleAtEveryProbe(ref:) |
| inplace-matrix | keepSuspect | KILLED | w6OneSuspectSuppressesTheWholeVerdict() |
| inplace-matrix | floorTwo | KILLED | w3TheWindowEdgeDropsAnIntervalAndThenTheVerdict() |
| inplace-matrix | windowTwoHours | TIMEOUT | (simulator wedged) |
| inplace-matrix | sustainedFromLatest | TIMEOUT | (simulator wedged) |
| inplace-matrix | medianNotMean | TIMEOUT | (simulator wedged) |

