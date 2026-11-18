# Hushlight — Backlog

One app: a contraction timer for the night labor starts, free forever and fully
private (`CLAUDE.md` owns the ratchet). Extracted from a private monorepo on
2026-08-23 (decision 0033). This file is the **ledger**: one line per item, its status,
and where the record lives. It is not the log — the narrative of what each item found,
measured and decided is `docs/BUILDLOG.md` (by date) and `docs/decisions/` (by number).
The build log before the source was opened (decision 0067) is not in this repository, so
a `log` date earlier than 2026-11-18 points at a record that stays private.

## 1 · How to read this file

**Status marks** (the lifecycle in `CLAUDE.md`): `[ ]` backlog · `[N]` next · `[~]` in
progress · `[R]` built, in self-review — something named still holds it · `[x]` done.
Two closed outcomes are not "built" and say so in bold on the line: **declined** (a human
chose not to) and **superseded** (another item made it moot). Both are `[x]`: the
question is settled, and the line says by what.

**Entry shape.** Status, ID, size, title, then one to three sentences on what it
delivers, then the trail:

```
- [x] **HL-0NN · S — Title.** What it delivers. *→ decision NNNN · F-00NN · log 2026-09-05*
```

`→ decision` is the numbered entry that owns the reasoning; `F-` the QA finding it
closed (`docs/qa/FINDINGS.md`); `log` the BUILDLOG date(s) of the work, or `pre-split`
for work done before the extraction. Sizes are XS S M L. IDs are
permanent and never reused: SP- items came from the monorepo, HL- items are
Hushlight's own. Numbering is not chronology — an item is filed when it is noticed.

**Where to look.** §2 is the only place work lives. §3 is what has shipped, grouped by
what it is rather than when it was filed, sorted by ID inside each group. §4 and §5
carry the human decisions and the listing stance for traceability.

**Closing an item** (DoD #4): the BUILDLOG entry carries the narrative; this line gets
its mark, its one-to-three sentences and its trail, in the same commit. Anything the
close leaves for a person goes into §2.2 as its own row, not into the closed line.

## 2 · Open — what still needs to be developed

### 2.1 · In flight

- [R] **HL-058 · L — Hushlight on iPad: a stand, or a hand.** Three layout regimes by
  size class, never by device — *compact* (today's column), *hand* (portrait: the
  instrument beside a live ledger of the stretch), *stand* (landscape: the count at the
  new `.distance` role) — all four orientations on iPad, keyboard and pointer, two iPad
  store frames in nine languages. No sync, by the ratchet: the iPad keeps its own record
  and Guidance says so. Design in `docs/design/hushlight/ipad/`. All three built
  sub-items are on `main` (PRs #42, #45; reviewed 2026-09-13). *→ decision 0064 ·
  F-0059 · log 2026-09-09, 2026-09-13*

  | Sub | Size | Scope | Status | What holds it |
  |---|---|---|---|---|
  | a | M | `LayoutRegime`, `LedgerPane`, `.distance`, orientations, `RegimeTests` | `[R]` | The AX5 gate on an iPad reports "Text clipped" on elements it cannot name while the screenshots show every text whole — **F-0059**, an attribution problem in the audit. Closes when the finding is attributed or dispositioned with a measurement. |
  | b | S | `KeyboardIntents`: Space, ⌘Z, ⌘J, ⌘G, Esc; hover on capsules and slab | `[R]` | Space and ⌘Z proven by `KeyboardTests` on the simulator; ⌘J, ⌘G and Esc need a Magic Keyboard on a real iPad (the harness delivers custom ⌘-letters intermittently and Esc into a sheet never). Christian's — §2.2. |
  | c | S | `StoreShotsPad`, iPad frames ×9, listing paragraph ×14, notes, push to the 13" slot | `[x]` | Merged 2026-09-13. **Consequence:** `main` now describes an iPad app — see the resubmission row in §2.2. |
  | d | — | AirDrop hand-off, Handoff | parked | Christian, 2026-09-09: "let's hold off on both." §2.3. |

  The iPad ships in **1.1** (Christian, 2026-11-02 — HL-068).

- [R] **HL-068 · XS — Ship 1.1 to TestFlight.** 1.0 is live (Christian, 2026-11-02);
  1.1 carries the iPad, the iPhone Duo and the three new ways in (HL-058, HL-060 –
  HL-065). `MARKETING_VERSION` 1.1, `release_notes/1.1.txt` ×14, uploaded through the
  Release workflow as 1.1 (6). Closes when the build has processed in App Store Connect;
  promoting it to testers is §2.2. *→ log 2026-11-02*
- [R] **HL-070 · S — Open the source.** MIT, a single fresh commit, nothing personal in
  the tree; public README, `LICENSE`, `CONTRIBUTING.md`. Held by the one step that is
  Christian's: creating the public repository and pushing the snapshot (gate 2).
  *→ decision 0067 · log 2026-11-18*

- [ ] **HL-059 · XS — The findings register's status table is stale.** The table at the
  top of `docs/qa/FINDINGS.md` still reads `open` for F-0040, F-0041, F-0042, F-0044,
  F-0045, F-0046, F-0047, F-0049 and F-0051, every one of which HL-021 through HL-027
  closed on 2026-08-26 (the per-finding sections below the table say so). Bring the
  table to the same state as the items, and say in the register's header that the
  table is the summary of record. Filed here, DoD #5, while standardising this file.

- [R] **HL-060 · S — A contraction survives the fold.** Opening, closing or propping a
  Duo mid-contraction resizes the window and can move the scene between panels; the
  running record, an open sheet, the navigation path and Undo must come through. Every
  piece of state a regime switch could rebuild already lives on `TimerScreen` (0064's
  boundary; the hinge pose joined it), and the running record lives in the store. Held
  by the one proof a simulator cannot give — a posed Duo, §2.2. *→ decision 0066 · log
  2026-10-28*
- [R] **HL-061 · M — Tabletop: the Duo half open on the nightstand.** A fourth
  `LayoutRegime`: a fold across a half-open window puts the count at `.distance` and
  then the verdict on the upright half, and gives the half lying flat to the slab, all
  of it. Book-held, the ledger snaps to the trailing panel. `FoldTests` prove the layout
  under a test-only `-simulateFold`; the system's own report of the fold waits for a
  posed Duo, §2.2. *→ decision 0066 · log 2026-10-28*
- [R] **HL-062 · S — The inner display's details.** Content stands off the
  under-display camera's occlusion region wherever it touches an edge (safe areas do not
  include it); sheets, the vertical toolbar and the portrait lock on the inner panel are
  still to be seen, because the simulated Duo boots closed and cannot be opened from a
  script. §2.2. *→ decision 0066 · log 2026-10-28*
- [R] **HL-064 · M — The iPhone Duo store set.** `StoreShotsDuo` and
  `shoot-store-duo.sh` capture one shot per pose (*Tabletop*, *Open*, *Cover*) and refuse
  a simulated fold; `make-store-frames.swift` frames both Duo panels; specs in nine
  languages; a Duo paragraph and the Control Center / Action button / Siri sentence in
  all fourteen descriptions; review notes updated. The English *Cover* raw is captured;
  the other two need the device posed, and the frames go up by hand — the API has no
  Duo display type. §2.2. *→ decision 0066 · log 2026-10-28*
- [R] **HL-065 · S — Start a contraction without opening the app.** The lock-screen
  intent as an App Shortcut (Siri: "Time a contraction with Hushlight"; the Action
  button) and a Control Center control, phrases and labels in nine languages. The intent
  speaks its result in Magic Tap's words and refuses to write if it ever runs outside
  the app. Held by a device check that each door runs it in the app's process, §2.2.
  *→ decision 0066 · log 2026-10-28*
- [ ] **HL-066 · S — Check the store's required iPhone set.** App Store Connect's
  screenshot reference (read 2026-10-28) lists the *medium* Dynamic Island iPhone set
  (6.3", 1206×2622) as always required and the large set as optional; ours is the 6.9"
  set alone. Confirm against App Store Connect itself and, if so, shoot the medium set
  with the existing pipeline before the next submission. Filed while building HL-064,
  DoD #5. *→ log 2026-10-28*
- [ ] **HL-067 · M — The UI suite on iOS 27.** On `main` as on this branch, all ten
  accessibility audits, the refused-call fallback test and the RTL tape caps fail on an
  iOS 27 iPhone simulator, and on the Duo three back-button lookups cannot see iOS
  27.1's vertical bars. Find which are the harness and which the app, and bring the
  suite back to green on the runtime that ships. Filed while verifying HL-060–065, DoD #5.
  *→ F-0061 · log 2026-10-28*

### 2.2 · Christian's — carried out of closed items

Every row is a human action a closed item left behind. Gates are `CLAUDE.md`'s: **1**
money, **2** credentials and releases, **device** a physical iPhone or iPad, **human** a
judgement no agent may make.

| What | From | Gate | Since |
|---|---|---|---|
| **Check the Live Activity replacement on a phone** (HL-069 changed which activities the sweep ends): start a contraction, change the rule so the activity is replaced, confirm exactly one remains on the lock screen. Then read `docs/qa/AUDIT-2026-11-09.md` — the review list — and say which rows become items. | HL-069 | device · human | 2026-11-09 |
| **Promote 1.1 (6)** in App Store Connect once it has processed: internal testers first, external through SP-083's group if wanted. Answer the export-compliance question only if it appears (the plist answers it). | HL-068 | 2 | 2026-11-02 |
| **Before submitting 1.1 for review:** the two iPad frames to the 13" slot (`--screenshots` does it now that the build is "1,2"), the Duo frames by hand (row below), HL-066's medium iPhone set if App Store Connect asks for it, and the Notes from `docs/app-store-review-notes.txt` on `main` — they describe this build. | HL-068 · HL-058c · HL-064 · HL-066 | 2 | 2026-11-02 |
| Confirm the age-rating questionnaire shows **13+** (medical or treatment information, infrequent) — the 12+ tier the docs name was retired in 2025 and migrated to 13+. | HL-056 | 2 | 2026-09-09 |
| One sentence on the live privacy page naming Copy and Share on the For the call card as the user's own hand-off, so "nothing is shared" cannot be read against the Share button. | HL-056 | 2 (his site) | 2026-09-09 |
| Tag the commits behind 1.0 (4) and 1.0 (5) as `hushlight-v1.0-b4` / `-b5` (decision 0020 wants every binary in the wild mapped to a commit; b1–b3 exist), `hushlight-v1.0` on the build that went live, and `hushlight-v1.1-b6` on the commit the 1.1 (6) run archived. | HL-045 · checklist | 2 | 2026-09-06 |
| A Magic Keyboard on the iPad: ⌘J opens History, ⌘G Guidance, Esc closes a sheet, holding ⌘ shows the HUD with Space greyed when the timer is not in front. Closes HL-058b. | HL-058b | device | 2026-09-09 |
| Someone who has not seen the app holds it at AX5 and finds what sits below the pinned bar. HL-028 removed the cause of the disagreement (the chevron cue); it did not run the test the entry asked for. | HL-028 · F-0048 | human | 2026-08-26 |
| The haptics through a contraction: `.start`/`.stop` are softer than the `.impact(.heavy)` they replaced, and whether they are felt mid-contraction was never recorded — no note was taken either way on the device runs. | SP-202 | device | 2026-08-23 |
| After release: Xcode Organizer ▸ Crashes and Hangs, and TestFlight before each later release — the only diagnostics channel the ratchet allows. | SP-217 · checklist | 2 | — |
| The keywords in fourteen storefronts are a reasoned first cut, unvalidated; an ASO tool to measure them against impressions is a purchase. | HL-010 | 1 | 2026-09-06 |
| The domain: hushlight.io unregistered, hushlight.com parked at ~$3k. Optional; the name is final without it. | HD-1 | 1 | 2026-08-27 |
| **Pose the iPhone Duo** — in Device Hub (the simulator named "iPhone Duo") or on a real one. Closed → open flat → half open with the fold across, mid-contraction each time: the record, an open sheet and the pushed screen survive (HL-060); half open shows the tabletop without `-simulateFold` (HL-061); open flat shows the ledger, the inner display's sheets and toolbar read right, and note whether it stays portrait (HL-062). Then `./scripts/shoot-store-duo.sh tabletop all` and `open all`, `make-store-frames` on `spec-duo`, and upload `frames-duo/` by hand to the Duo slot (HL-064). | HL-060 · HL-061 · HL-062 · HL-064 | device · 2 | 2026-10-28 |
| On a device: run the contraction from Control Center, the Action button and Siri, and confirm each lands in the app's History (a write in the extension's sandbox would be refused and logged as `intentRefusedOutsideApp`). Look at the Live Activity on the Always-On display of both Duo panels. | HL-065 · HL-063 | device | 2026-10-28 |
| HL-025's two drafted call-card bullets (second-stage pressure; the preeclampsia family) sit in the archive with the reviewer's open questions. Declined under decision 0060; worth putting in front of a clinician if one is ever engaged. Not a reopening. | HL-025 · F-0043 | human | 2026-09-05 |

### 2.3 · Parked

- **HL-058d — AirDrop hand-off and Handoff between iPhone and iPad.** Christian's
  hold, 2026-09-09. The iPad keeps its own record, and that is the design until he says
  otherwise. Nothing is built; nothing is scaffolded.

### 2.4 · Open findings with no item (see `docs/qa/FINDINGS.md`)

| F | Class | What | Owner |
|---|---|---|---|
| F-0062 | tooling · S3 | `newest-sim.sh iPhone` picks the two-display iPhone Duo; `simctl io screenshot` refuses it, so the harness shot nothing. HL-069 makes zero shots fail the stage; the picker is unchanged. | unfiled |
| F-0061 | tooling · S3 | The UI suite fails on iOS 27 simulators, on `main` too — the audits, two tests, three Duo back-button lookups. | HL-067 |
| F-0059 | tooling · S3 | The AX5 audit on an iPad reports clipped text it cannot attribute; counts move on unchanged screens. | HL-058a |
| F-0054 | tooling | `ScaleBenchTests`' P99 timing threshold failed under machine load and passed idle. Since 2026-11-17 it takes the best of three rounds; watch whether it still flakes. | HL-069 |
| F-0027 | design-gap · S2 | Phantom taps in a coupled trough defeat the share statistic — a different mechanism from F-0008. Accepted recording-fidelity limitation since SP-194. | unfiled |
| F-0019 · F-0020 · F-0023 | harness | Snapshot moment picker on boundaries; only 5-1-1 ever seeded in app passes; the shots stage asserts nothing. All depend on the `expectedFacts` stage that F-0030 (fixed) made execute. | unfiled |
| F-0033 | accepted-limitation · S0 | Toolbar links do not scale with Dynamic Type — system furniture. | none |

## 3 · Shipped — what has been developed

### 3.1 · The instrument — timer, engine and verdict

Start-to-start intervals, evidence floors, a verdict that reports a pattern against the
rule the user chose. The engine is `LaborKit`, dependency-free (decision 0018); every
change to a rendered fact lands in the oracle and the harness in the same edit.

- [x] **SP-180 · M — `LaborKit` package.** Two-timestamp `ContractionRecord` on a local
  `ModelContainer` (no App Group), episodes split at a two-hour gap, `PatternAnalysis`
  with evidence floors (no average under three contractions, no verdict until the window
  spans it and holds six), rules 5-1-1 / 4-1-1 / 3-1-1, records over three minutes
  flagged suspect. *→ decision 0018 · pre-split 2026-08-10*
- [x] **SP-181 · M — App target and timer screen.** One giant start/stop control; the
  running state *is* the stored timestamp, so lock, background and kill lose nothing; a
  readout cluster against the chosen rule; an em dash, never a zero, below a floor. No
  entitlements of any kind. *→ pre-split 2026-08-10*
- [x] **SP-184 · S — Simulated-labor device pass.** DEBUG-only seeds (`-seedLabor511`,
  `-seedLaborYoung`, `-seedLaborWipe`) drove the met, young and wiped states onto the
  phone; two accessibility-type §8 failures found and fixed on the way. *→ pre-split
  2026-08-10*
- [x] **SP-185 · S — Follow-ups filed, not built.** The list that became SP-186 (Live
  Activity), SP-206 (export) and later items; the Watch app stays in the parking lot.
- [x] **SP-201 · S — Name the unmet leg of the rule.** When exactly one leg is missing,
  `missingLegLine` states it as measured fact — never a countdown — and the spoken form
  leads with the absence. *→ pre-split 2026-08-23*
- [x] **SP-202 · S — Distinct start/end haptics.** `.start`/`.stop` textures from the
  same state the lock-screen intent writes; undo and delete are felt too. The
  felt-through-a-contraction half is a device check that was never recorded (§2.2).
  *→ pre-split 2026-08-23*
- [x] **SP-203 · M — Catch the mis-tap, at the button and in the averages.** Records
  under twenty seconds are flagged `CHECK · UNDER 20 S` and excluded like the long side;
  a self-dismissing strip above the slab offers Delete. The threshold was measured on the
  corpus, not guessed. *→ decision 0032 · F-0035 · pre-split 2026-08-23*
- [x] **SP-204 · S — Acknowledge the forgotten timer while it runs.** Past three minutes
  the running record says so on the caption and the NOW node, spoken once on demand; no
  auto-end, no cap. *→ pre-split 2026-08-23*
- [x] **SP-207 · M — A faster-than-the-rule branch.** An early verdict when two-thirds of
  intervals sit under half the rule's spacing with normal durations for twenty minutes;
  `met` outranks it the moment the hour completes. Found the corpus hole F-0037 (corpus
  3.1.0). *→ decision 0040 · log 2026-08-24*
- [x] **SP-208 · S — Caption the tick tape.** **Superseded** by decision 0037: the
  derived-fill gauge it would have captioned was retired with HL-003 slice 2, and the
  ember tape shows the raw record, so bar and words cannot disagree.
- [x] **SP-209 · S — Irregular early spacing: name it, and license rest.** `EarlyIrregular`
  (1.5× bounds on both axes) plus one permission-giving sentence pinned verbatim in
  LaborKit; `-seedLaborIrregular`. *→ decision 0041 · log 2026-08-24*
- [x] **SP-211 · S — The met verdict earns the screen's one moment of priority.**
  **Absorbed** into HL-003 slice 3, verdict as dawn; its ACs travelled with the slice.
- [x] **HL-011 · S — The screen stays awake while timing.** `isIdleTimerDisabled` tied to
  a running contraction in the active scene, never to the app merely being open;
  confirmed on a physical phone through a full night. *→ log 2026-08-24, 2026-09-05*
- [x] **HL-012 · S — The optional heartbeat haptic.** A soft tick every fifteen seconds
  while timing, off by default, toggle in Guidance, silent in Low Power Mode, derived from
  the 1 Hz `TimelineView` with no timer armed. *→ log 2026-08-24*
- [x] **HL-016 · M — Trend captions with real deltas.** One statistic evaluated against
  the hour before it, both floors required, silent inside one-sixth, direction in words
  with colour seconding; engine and oracle agree across the corpus. *→ decision 0043 ·
  log 2026-08-24*
- [x] **HL-017 · M — The counted breath pacer, opt-in.** "in 1 2 3 4 · out 1 2 3 4 5 6"
  under the live numeral, counted from the wall clock; the numbers keep counting under
  Reduce Motion; hidden from VoiceOver. *→ log 2026-08-24*
- [x] **HL-021 · S — One question, one figure.** The hour-window legs and the
  whole-stretch call script each name their scope (History's band reads `THIS STRETCH ·
  …`, the call card footnotes the difference); the false "Tonight so far" VoiceOver
  grouping corrected. *→ decision 0047 · F-0040 · log 2026-08-26*
- [x] **HL-030 · M — Night-to-night vocabulary.** `StretchComparison` reads the live
  stretch's average interval against the one before it behind four gates, storing
  nothing new, and can say "about the same as your last stretch"; `-seedLaborSecondNight`.
  *→ decision 0050 · F-0050 · log 2026-08-26*

### 3.2 · History, corrections and closure

- [x] **SP-182 · S — History and corrections.** Episode-sectioned list, swipe delete, one
  toolbar Undo covering started, ended and deleted; suspect rows read `CHECK · OVER 3
  MIN` until their owner deletes them. *→ pre-split*
- [x] **SP-189 · S — Empty state, History polish, and clear-all.** The instrument at rest
  as the empty state, per-episode summary bands, Clear All History behind a confirmation.
  *→ pre-split 2026-08-13*
- [x] **SP-206 · M — "For the call" summary and text export.** A readable script composed
  in LaborKit (a clause below its floor is omitted, never dashed), one tap from the
  verdict and Guidance, with Copy and a user-initiated share sheet; "SPAN" became "OVER".
  *→ decision 0039 · log 2026-08-24*
- [x] **SP-212 · S — An explicit Cancel on Clear Everything.** A stated `role: .cancel`;
  the entry moved to a toolbar menu so scroll inertia cannot reach it; no destructive
  role, because red is not in the palette. *→ log 2026-08-24*
- [x] **SP-214 · S — Date the episode across midnight.** `EpisodeDay.describe` (DST-safe,
  backwards-clock-safe); "SINCE YESTERDAY 5:13 PM"; day-marker rows in History;
  `-seedLaborMidnight`. *→ log 2026-08-24*
- [x] **SP-215 · M — Closure: when the timing is over.** Three days stale, the timer
  screen shows a recap line over two quiet capsules, Keep a copy and Clear the
  instrument; "Save a copy first…" leads every clear path; no congratulations, no baby,
  ever. *→ decision 0029 §1 · log 2026-08-24*
- [x] **HL-015 · M — The pinned leg header on History.** Apart / long / holding with
  filled or open markers — measured quantities, never a progress bar — rendered through a
  shared `LegRows.swift` so the two surfaces cannot drift. *→ log 2026-08-24*
- [x] **HL-018 · S — Heal a split contraction, don't only delete it.** "Merge Up" beside
  Delete on a too-short row, extend-before-delete ordering, one Undo restoring both
  records with their identities. *→ log 2026-08-24*
- [x] **HL-022 · S — History rows show their seconds.** Rows and the export print
  `8:34:57`, so a printed gap can be checked against two printed times; standalone clock
  readings keep the minute. *→ decision 0048 · F-0041 · log 2026-08-26*
- [x] **HL-024 · M — The call summary, before the verdict.** The button sits under the
  partial state's sentence; the card takes its title from the offer that opened it — For
  the call during a stretch, Keep a copy after one. *→ F-0044, F-0047 · log 2026-08-26*
- [x] **HL-026 · S — The recap says when.** "Last stretch, Sat, Aug 22: …", the year only
  when it is not this one; spoken form dated to match. *→ F-0046 · log 2026-08-26*
- [x] **HL-027 · S — Cleaning up a long night.** "Delete N Flagged…" sweeps only what the
  engine marks CHECK, never a running contraction, as one Undo. *→ F-0049 · log
  2026-08-26*

### 3.3 · Lock screen and Live Activity

- [x] **SP-186 · M — Live Activity: timing from the lock screen.** Elapsed via
  `Text(timerInterval:)`, start/end as a `LiveActivityIntent` executing in the app's
  process — which is what keeps the store in the app sandbox with no App Group;
  `HushlightWidgets` renders lock screen and Dynamic Island from DesignKit tokens.
  *→ decision 0019 · pre-split 2026-08-10*
- [x] **SP-205 · S — Rearm the Live Activity from the lock-screen intent.** One
  `needsReplacement(now:)` predicate shared by the app and the intent, six-hour rearm
  under ActivityKit's eight-hour kill. *→ decision 0028 · log 2026-08-24*
- [x] **SP-213 · S — The lock screen leads with the average.** "AVG 5:00 APART · 14" above
  the app's own floor, a labelled "LAST" fallback, a spoken form. *→ log 2026-08-24*
- [x] **HL-013 · M — StandBy: the nightstand is literal.** The Live Activity is the StandBy
  surface (a widget would need the App Group the ratchet forbids); honours
  `isLuminanceReduced`; confirmed on a physical nightstand through a full night.
  *→ decision 0042 · log 2026-08-24, 2026-09-05*
- [x] **HL-063 · S — The Live Activity in the Duo's vertical island.** Photographed on
  the iPhone Duo simulator: the compact count broke inside itself in the narrower
  vertical slot; now one line, every glyph inside the island. `IslandTests` keep the
  photograph. The Always-On check rides HL-065's device row. *→ decision 0066 · F-0060 ·
  log 2026-10-28*

### 3.4 · Guidance, How It Works and the first launch

- [x] **SP-183 · S — Guidance screen.** What the rule means, the picker, the
  call-right-away card, the "stopwatch with arithmetic" disclaimer; every verdict defers
  to the provider's instructions. *→ pre-split*
- [x] **SP-190 · S — How It Works.** Six lessons taught with the app's own instruments,
  shown once on first launch and reachable forever from the toolbar `?`; never gates the
  timer. *→ pre-split 2026-08-13*
- [x] **SP-200 · S — Provider number and call button.** One optional field in Guidance
  (UserDefaults, stays on the phone); `ProviderContact` is the one definition of
  dialable; Call renders on the verdict and the call-now card only when set.
  *→ pre-split 2026-08-23*
- [x] **SP-216 · S — Review prompt, under 0029 §2.** A pure `ReviewPrompt.isEligible`, one
  attempt per install, never near a live episode or a closure, never from the lock
  screen; "Rate on the App Store" beside Privacy and Support, the row stacking via
  `ViewThatFits`. *→ decision 0029 §2 · log 2026-08-24, 2026-09-05*
- [x] **SP-217 · M — Diagnostics without analytics, under 0029 §3.** MetricKit summaries
  kept locally; "Report a problem" drafts a `mailto:` whose visible, deletable block
  never carries contraction data; `Breadcrumb`'s closed enum is the only logger,
  enforced by `lint-logging.sh`. *→ decision 0029 §3 · log 2026-08-24*
- [x] **HL-014 · S — The three promises, on first launch.** "Free forever · no account ·
  works in airplane mode" under the greeting. Verifying it traced the phantom
  never-showing sheet to a device-level preference `shoot-store.sh` now clears.
  *→ log 2026-08-24*
- [x] **HL-025 · S — Call-right-away: clinical completeness.** **Declined.** Two bullets
  (second-stage pressure; the preeclampsia family) were drafted, reviewed and reverted
  because an agent cannot satisfy its own human gate; Christian chose not to add them.
  The wording and the reviewer's questions survive in the archive. *→ decision 0060 ·
  F-0043 · log 2026-09-05*
- [x] **HL-029 · S — The long-haul copy questions.** The bare `?` glyph named in words
  (F-0053); the ageing verdict deliberately left alone (F-0052); night-to-night split out
  as HL-030. *→ decision 0049 · log 2026-08-26*
- [x] **HL-052 · XS — The in-app policy links follow the reader's language.**
  `PolicyLinks.swift` maps the localization the app resolved to onto the site's segment
  (Spanish outside Spain → es-MX, French outside Canada → fr-FR); anything unrecognised
  falls back to the English path. *→ log 2026-09-06*
- [x] **HL-057 · XS — Two buttons that can do nothing on the wrong device.** Call and
  Report a problem use `openURL`'s completion and on refusal show `HandoffFallback` —
  the number or address written out, with Copy. Ships in 1.0.1. *→ log 2026-09-09*

### 3.5 · Design and identity

The name and the Nightstand identity were researched and decided on 2026-08-23
(`docs/design/hushlight/`; decision 0033); the structural rename shipped with the
extraction as HL-000. Fonts and colours are defined in DesignKit and nowhere else.

- [x] **SP-187 · M — UI refinement with Claude Design.** The inline episode timeline, the
  circle button, the guideline chip, dark-first, from cards in the Claude Design project.
  *→ pre-split 2026-08-13*
- [x] **SP-188 · S — Polish pass.** The first icon, gradient depth, the breathing glow,
  numeric-roll transitions, Reduce Motion throughout. *→ pre-split 2026-08-13*
- [x] **SP-191 · S — Code review of the design arc.** Ten findings fixed; start-to-start
  math unified in `PatternAnalysis.interval(from:to:)`; `lint-literals.sh` became the one
  definition of the literal gate. *→ pre-split 2026-08-13*
- [x] **HL-001 · M — Nightstand tokens in DesignKit.** Warm near-black room, one ember
  accent, sage go-time, warm paper light mode; `PaletteContrastTests` recompute every
  ratio from the shipped values, which found three sub-AA runtime mixes and made them
  tokens. *→ decision 0034 · log 2026-08-23*
- [x] **HL-002 · S — The ember icon.** Four PNGs from `make-hushlight-icon.swift`, the
  marketing slot carrying the dark artwork. Replaced by HL-034. *→ decision 0035 · log
  2026-08-24*
- [x] **HL-003 · L — Nightstand screen language.** Four slices: the full-width slab and the
  hero leaving the disc; the ember tape (bar width is duration, gap is interval, grid at
  the rule's own spacing); verdict as dawn ("It looks like time." in `.voice` over the
  sage wash); the breath-paced glow. *→ decisions 0036, 0037, 0038 · log 2026-08-24*
- [x] **HL-004 · S — Listing and docs take the name.** Title `Hushlight - Contraction
  Timer`, the subtitle freed for the differentiators, keywords at exactly 100.
  *→ log 2026-08-24*
- [x] **HL-034 · S — The icon redesigned: two marks and the interval between them.**
  Rejected by Christian the same day; replaced by HL-035. *→ decision 0051 · log
  2026-08-27*
- [x] **HL-035 · S — The icon is a lamp.** The shade-fills-the-frame render rebuilt as
  vector source from palette tokens. Replaced by HL-042. *→ decision 0052 · log
  2026-08-27*
- [x] **HL-042 · S — A classic table lamp icon.** Tapered linen shade, brass stem, round
  base; four opaque 1024² exports, verified at 29/40/60 px. The icon in every build from
  1.0 (3). *→ decision 0055 · log 2026-09-05*
- [x] **HL-044 · S — How It Works reads through its own bar.** `.bar`'s translucency
  replaced by `Palette.raised` plus a hairline, and the hard scroll edge; measured at
  spread 0 on iOS 18.5 and 26.4 in both appearances. *→ log 2026-09-05*

### 3.6 · Accessibility

Dark appearance and accessibility type are the primary environment, not an audit
checkbox. The AX5 gate runs with zero suppressions; `lint-row-figures.sh` guards the
reflow class the audit cannot see.

- [x] **SP-195 · L — Accessibility conformance (HIG + WCAG AA).** Two-tier AA in the quiet
  register, the disc squared, the verdict leading at accessibility sizes, 44 pt targets;
  the AX5 audit and `LayoutInvariantTests` in CI. F-0038 (`hitRegion` is `LegRowView`'s
  read-only rows) and F-0032 (`dynamicType` false positive) dispositioned with
  measurements. *→ decisions 0027, 0057, 0058 · pre-split 2026-08-17 · log 2026-09-05*
- [x] **SP-210 · S — Magic Tap + VoiceOver order.** Two-finger double-tap anywhere starts
  or ends; the announcement speaks the result — "Recorded 1 minute 2 seconds".
  *→ log 2026-08-24*
- [x] **HL-019 · M — Triage the light + default-type accessibility leg.** Four real
  contrast gaps fixed with two new tokens, nine findings pixel-disproven, the `hitRegion`
  pile located by `SmallTargetDiagnostics` and accepted. *→ decisions 0044, 0057 · F-0034,
  F-0038 · log 2026-08-24, 2026-09-05*
- [x] **HL-023 · S — Three figures VoiceOver cannot read.** Spoken forms for History's
  summary band, a leg's met state ("not yet") and the tape's end caps. *→ decision 0038 ·
  F-0042, F-0045, F-0051 · log 2026-08-26*
- [x] **HL-028 · S — The AX5 fold: reachable, or found?** A chevron in the pinned bar's
  top edge, lit only while content remains below, its predicate measured against the
  real inset arithmetic. The user test it asked for is still open (§2.2). *→ F-0048 ·
  log 2026-08-26*
- [x] **HL-031 · S — The timeline collapses at AX5.** `EpisodeTimeline` takes the
  `isAccessibilitySize` branch and stacks; a layout invariant pins the connector's hole.
  *→ F-0055 · log 2026-08-26*
- [x] **HL-032 · S — History's rows shred at AX5.** `HistoryRow` stacks its three figures
  in reading order; no invariant can see this class, so HL-033 was filed instead.
  *→ F-0056 · log 2026-08-26*
- [x] **HL-033 · S — Nothing here can see reflow.** `lint-row-figures.sh`: two or more
  `.dataText(.row)` figures in a file that never mentions `isAccessibilitySize` fails the
  build; proven against both historical defects. *→ F-0057 · log 2026-08-26*

### 3.7 · QA harness and engineering

- [x] **SP-193 · L — Labor QA harness.** A 408-scenario corpus, an oracle with zero
  imports, three legs, 165 tests in about twenty seconds; the first run registered 26
  findings. *→ decision 0021 · pre-split 2026-08-16*
- [x] **SP-194 · M — QA findings, first fix wave.** Four waves, 26 findings closed, corpus
  2.0.0, 413/413 T0-clean; F-0019, F-0020, F-0023 and F-0027 named open rather than
  rounded up. *→ decisions 0022–0026 · pre-split 2026-08-17*
- [x] **HL-020 · S — The generated project notices it is stale.** `build.sh` regenerates
  when `project.yml` or the app-target tree is newer than the project, and every script
  builds through it. *→ log 2026-08-24*
- [x] **HL-038 · S — The floor was never chosen.** iOS 27 down to 18.0, the one iOS 26
  call behind `#available`, the Xcode-beta pin gone, SP-042a closed. *→ decision 0053 ·
  log 2026-09-05*
- [x] **HL-039 · S — Walk the gates below iOS 26.** `walk-gates.sh` on 18.5 and 26.4: the
  app is sound on both, AX5 on 18.5 zero findings; found HL-044. *→ log 2026-09-05*
- [x] **HL-041 · M — LaborSim has no business on a simulator.** **Built, measured,
  declined**: native macOS was 7% faster; two `#if canImport(ActivityKit)` guards that
  gated nothing became `#if os(iOS)`. *→ decision 0056 · log 2026-09-05*
- [x] **HL-043 · M — Make the QA suite faster where it is actually slow.** The cost was in
  the app, not the harness: `presentedLatch` fuses two identical ten-minute walks, 2.03×
  per call; mutation matrix 6/6 killed. *→ decision 0059 · log 2026-09-05*
- [x] **HL-069 · M — Whole-project audit.** Every file read; what was certain fixed (the
  Live Activity replacement sweep, the harness's tick-tape fact and silent exits, dead
  code, stale docs), the rest listed for Christian in `docs/qa/AUDIT-2026-11-09.md`.
  *→ log 2026-11-09*

### 3.8 · Localization

Nine locales — en, es, fr, de, it, pt-BR, ja, ko, zh-Hans — as build-time assets in the
binary; the medical copy verified under decision 0061. `docs/i18n/maps/*.py` is the
translation source; `apply-language.py` must round-trip the catalog unchanged.

- [x] **HL-006 · L — Localization foundation.** String Catalogs per module, every entry
  carrying translator context, `lint-localizable.sh` in the gate, a pseudolocale leg;
  `en` byte-identical. *→ log 2026-08-25*
- [x] **HL-007 · M — Grammar that survives translation.** Positional format strings and
  catalog plurals; the opaque pinned bar and the icon toolbar entry fell out of the
  pseudolocale's findings. *→ log 2026-08-25*
- [x] **HL-008 · M — The first language wave.** Nine locales, 218 keys each;
  `VerifiedLanguages` and `LanguageGateTests` keep an unverified medical surface out of
  the binary; per-language `neverSays` lists cut for the idiom. *→ decisions 0061, 0062 ·
  log 2026-08-25, 2026-09-05*
- [x] **HL-009 · S — RTL and non-Latin scripts.** The tape pins left-to-right as one unit
  while the screen mirrors; direction-aware chevrons; type fallback measured, not
  assumed. *→ decision 0045 · log 2026-08-25*
- [x] **HL-046 · S — HL-006 and HL-007 both left residue, and only a real locale showed
  it.** `SWIFT_EMIT_LOC_STRINGS` turned on (53 missing keys found, 16 stale removed),
  `lint-loc-catalog.sh`, rules 4–6 in `lint-localizable.sh`, the mono-caps band
  localized. *→ decision 0063 · log 2026-09-05*

### 3.9 · Release pipeline, the store and App Review

Uploads only: the pipeline archives, validates and uploads; promotion, TestFlight and
submission stay in App Store Connect under gate 2. No agent handles the API key.

- [x] **SP-196 · M — App Store submission prep.** Privacy manifests, the encryption
  exemption, store docs and the checklist; submitted 2026-09-05 after a full night of use
  on a device. Closing it found the icon gap that became HL-045. *→ decision 0028 · log
  2026-08-25, 2026-09-05*
- [x] **HL-005 · S — `/hushlight/` pages live.** Privacy and support at
  `christianwainright.com/hushlight/*`, copy and handoff brief in `docs/`; live and
  accepted 2026-09-05. *→ log 2026-08-27*
- [x] **HL-010 · S — Localized store presence.** Fourteen storefronts (Apple splits
  es-ES/es-MX, fr-FR/fr-CA and four English variants), keywords tuned per market; the
  listing live and 98 screenshots accepted 2026-09-06. *→ log 2026-09-06*
- [x] **HL-036 · M — The release pipeline, uploads only.** `release.yml` archives, verifies
  both privacy manifests are in the archive, exports, validates, uploads, and never
  promotes; proven with 1.0 (1). The key must be Admin, not App Manager. *→ decision
  0031 · log 2026-08-27, 2026-09-05*
- [x] **HL-037 · M — The store set, framed.** Seven frames composed onto the Nightstand
  room, two previews at the 6.9" spec from real footage of the app. *→ log 2026-09-05*
- [x] **HL-040 · S — The uploaded build was made with a beta Xcode.** Both macOS jobs on
  `macos-latest` with a beta-suffix warning; 1.0 (2) archived on Xcode 26.6.
  *→ log 2026-09-05*
- [x] **HL-045 · S — The build under review has the old icon.** 1.0 (3) uploaded from
  `b5b629d` with the lamp and nine locales; tags `hushlight-v1.0-b1`, `-b2`, `-b3` cut.
  *→ decision 0020 · log 2026-09-06*
- [x] **HL-047 · M — Push the listing to App Store Connect from CI, on ubuntu.**
  `push-store-metadata.py` and `asc_jwt.py` (ES256 via `openssl`, no dependency); a
  read-only diff by default, `--apply` to write; `listing.yml`. *→ log 2026-09-06*
- [x] **HL-048 · M — Localized screenshots, captured locally and committed.** The
  `StoreShots` suite navigates by accessibility identifier, `shoot-store.sh sweep` runs
  it per shot; 56 frames across eight languages; `05-lockscreen` stays hand-staged.
  *→ log 2026-09-06*
- [x] **HL-049 · S — Description and promotional text per storefront.**
  `docs/store/metadata/<storefront>/<field>.txt` is the source of truth;
  `lint-store-metadata.sh` checks the disclaimer verbatim, keyword overlap and that the
  policy URLs agree with `PolicyLinks`. *→ log 2026-09-06*
- [x] **HL-050 · XS — The localized pages serve translated copy under `lang="en"`.** Fixed
  on the website; the finding recorded in the pages handoff so
  it outlives the fix. *→ log 2026-09-06*
- [x] **HL-053 · XS — Release notes per storefront, before 1.0.1.**
  `release_notes/<version>.txt` ×14, sent as `whatsNew` when the file exists; the lint
  requires the file for the project's `MARKETING_VERSION` unless it is 1.0.
  *→ log 2026-09-09*
- [x] **HL-054 · XS — A device build that stays at the met verdict.** `-seedLabor511Always`
  re-seeds every cold launch (DEBUG only, verified absent from a Release binary) and
  remembers the provider number. *→ log 2026-09-06*
- [x] **HL-055 · S — App Review round 2: three findings, none of them in the binary.**
  Subtitles lead with *private*, not *free* (a price-word lint); the notes stop naming
  WidgetKit and say there is no widget; both previews re-rendered full-bleed.
  *→ log 2026-09-09*
- [x] **HL-056 · S — A reviewer's pass over the whole submission before round 3.** The
  notes now name Copy and Share and describe the early verdict a reviewer can reach;
  every other guideline checked with its answer recorded in the log. *→ log 2026-09-09*
- [x] **HL-051 · S — Close App Review for 1.0.** Three rounds: a 2.1 information request
  answered in the notes, three metadata findings fixed by HL-055, round 3 prepared by
  HL-056. 1.0 approved and live (Christian, 2026-11-02). *→ log 2026-09-06, 2026-09-09,
  2026-11-02*

## 4 · Human decisions (HD)

All four are resolved; the rows stay because other files cite them.

| ID | Decision | Outcome |
|---|---|---|
| HD-1 | The name | **Hushlight, final** (Christian, 2026-08-27). USPTO: an identical string is registered in Class 7 (wood splitters, generators) to an unrelated owner; the app's own classes are clear. Risk accepted; no attorney engaged. The domain is optional and behind the money gate — §2.2. |
| HD-2 | App Store Connect record | **Done** — `net.wainright.hushlight`, app id 6806088681; 1.0 submitted 2026-09-05. |
| HD-3 | Analytics | **None, ever** — decision 0029 and the ratchet. |
| HD-4 | Which languages, and who verifies the medical copy | **Nine locales; the agent translates and Christian accepts that as the verified read** — decision 0061, 2026-09-05, recorded as his acceptance rather than an agent's signature. For ja, ko and zh-Hans the acceptance is trust rather than an independent read. |

## 5 · Listing positioning (carried from SP-171)

From the 2026-08-10 competitor scan: the category incumbent onboards through
fabricated urgency ("100,000 women are counting contractions right now"),
quiz-gates the timer, loss-frames ("Without us: anxiety"), runs banner ads under
the labor button, and prints an "avg frequency" from two intervals. Our listing
copy is the inversion, stated plainly: opens on the button, no account, no ads, no
network, and no figure below its evidence floor. Do not name the competitor;
describe ourselves.
