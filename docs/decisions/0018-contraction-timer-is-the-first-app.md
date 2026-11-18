# 0018 — The contraction timer is the ecosystem's first app, on its own store

**Status:** accepted (direction set by Christian, 2026-08-10; design agent-decided)
**Date:** 2026-08-10
**Amends:** decision 0017's sequencing — a new phase A1 is inserted and 0017's
A1–A5 are relabelled A2–A6. Item IDs (SP-130s…170s) are unchanged. 0017's
architecture is otherwise untouched.

## Context

Christian called a new first app for the ecosystem: a contraction timer for a
mom-to-be — count contractions, their duration, the interval between them, and how
long the pattern has been going, so she knows when it is time to go to the hospital.
Completely free forever; later the other apps cross-link for anyone who wants them.

It has a fixed deadline the other apps do not, so it ships first.

## Decision

**One new app — working title "Setpoint Contractions" (marketing name is an A6/OD-5
question) — inserted as phase A1, built on its own local store.**

### Ecosystem membership means the design system, not the shared store

Decision 0017 established one App Group store for the fitness suite. This app is
deliberately **outside** it:

- Labor data is not fitness data. No tracker or coach feature reads it, ever; a
  digest must never contain it. The cheapest way to make both true is the same move
  the sensitive-data fences use: make the wrong thing unreachable, not filtered.
  Contraction records live in a container the other apps cannot open.
- The dependency also points the right way round: the timer must not carry the
  fitness schema, its migrations, or its version-gate lockstep. A person in labor
  does not update three other apps first.
- What makes it part of the ecosystem is **DesignKit** — the hairline-instrument
  language, the type roles, the tick-tape gauges — plus, later, the cross-links
  Christian named. Shared identity, separate data.

Concretely: a new `LaborKit` package owns a `ContractionRecord` schema, its own
`ModelContainer` in the app's sandbox (no App Group entitlement needed), episode
grouping, and the pattern analysis. The app target holds only screens. Package-level
tests execute today, which the app-target suite cannot (SP-042a) — the same reason
the engines live in packages everywhere else.

### What it measures, and what it will not say

- **Duration** of each contraction; **interval** measured **start-to-start** (the
  clinically standard frequency measure — end-to-start understates frequency and
  some timer apps get this wrong); **pattern length** since the first contraction of
  the current episode. A gap longer than two hours starts a new episode — early
  labor stops and restarts across days, and yesterday's cluster must not pollute
  tonight's averages.
- **The guideline is 5-1-1** (contractions every ≤5 minutes, lasting ≥1 minute,
  sustained for 1 hour), presented as the widely used rule it is, with 4-1-1 and
  3-1-1 selectable because providers instruct differently. When the last hour meets
  the selected rule, the app says so and suggests calling the provider —
  measurements first, then the call, in the coach voice. It **never** says "you are
  in labor," never says "you don't need to go yet," and never issues a command.
  No-medical-claims is already a voice rule; here it is also the App Review line.
- A reference card lists the situations where the guideline is irrelevant and the
  answer is call now regardless: water breaking, bleeding, reduced fetal movement,
  contractions before 37 weeks. Stated once, calmly, always reachable — information
  display, not diagnosis.
- **Minimum evidence before figures render** (the SP-053 rule, reapplied): no
  interval average until three contractions exist; no guideline verdict until the
  window genuinely spans it. A confident figure over two data points is the same
  lie the adherence cluster used to tell.

### Built for the moment of use

- **One giant button.** Tap when a contraction starts, tap when it ends. The whole
  lower half of the screen, one-handed, no aim required. Everything else is
  read-only glanceable state.
- **Wall-clock truth.** Running state derives from stored timestamps, never from a
  live timer — locking the phone, backgrounding, or the app dying mid-labor loses
  nothing. Same principle as the rest-timer derivation in Train.
- **Mis-taps are expected.** Delete any contraction; undo the last action. A
  contraction left running past several minutes is visually flagged as suspect
  rather than silently averaged in.
- Dark appearance and XL type are not gate formalities here; 3am in a dark room is
  the primary environment. §8 gates apply in full.

### Free forever

No IAP target, no paywall surface, no analytics (SP-082's stance extends), no
network capability at all in v1. Nothing leaves the device; there is nothing to
consent to.

## Alternatives rejected

- **Inside the shared App Group store.** See above — no reader benefits, and the
  schema/lockstep coupling is pure cost. Rejected on the same grounds 0017 rejected
  CloudKit: an architecture choice must not widen where sensitive data can flow.
- **A HealthKit-backed record.** HealthKit has no contraction sample type; inventing
  a workout-shaped stand-in would be semantically false and export someone's labor
  into every app with workout read access.
- **Folding it into a future "family" app.** Speculative scope. One job, done
  excellently, shippable in weeks.

## Consequences

- The suite is five apps. CLAUDE.md and BACKLOG §1 updated; phase table gains A1
  and relabels the rest (IDs stable).
- `project.yml` gains the app target when SP-181 starts; `LaborKit` needs no
  project change until then.
- Follow-ups filed, not built: Live Activity lock-screen timing (probably the
  single most useful addition — labor happens on the lock screen), a
  share-with-triage text export, a Watch app (parking lot), and the cross-app
  links once siblings exist.
