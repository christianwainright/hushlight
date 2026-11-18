# 0029 — Feedback, reviews, and diagnostics keep the promise

> Copy carried out of the Setpoint monorepo at the Hushlight extraction (governs SP-216/SP-217 here);
> the Setpoint original governs that repo. See decision 0033.

**Status:** accepted (filed with the A1.2 backlog, 2026-08-23)
**Date:** 2026-08-23

## Context

Three requests arrived together after the simulated-mother UX pass: a closure
feature for when labor is over, an App Store review prompt ("need to be real
careful how we do this"), and an answer to the troubleshooting question — if a
user reports a problem, what data do we actually have?

All three press on the same wall. The app's shipped copy says "No account, no
ads, no network. Everything stays on this phone" — printed in Guidance, restated
in the privacy manifest and review notes (SP-196), load-bearing for App Review
and for the product's entire wedge. And the subject matter carries a risk no
other app in the suite has: **not every labor ends with a healthy baby.** Any
feature that celebrates, congratulates, or assumes an outcome will, for some
real person on the worst night of her life, be unbearable.

## Decision

### 1. The app never assumes an outcome

Nothing in the closure flow, the review prompt, or any copy anywhere presumes
the episode ended in a birth, or that a birth was joyful. The instrument
registers that a stretch of contractions ended; it does not narrate what
happened next. No "congratulations," no baby iconography, no confetti. The one
warm register permitted is the instrument's own: calm acknowledgment that its
job here is done. This is a ratchet like the sensitive-data invariants: no
future item may relax it for engagement reasons.

### 2. Reviews: the system API, at a calm moment, never twice

- `RequestReviewAction` (StoreKit's `requestReview`) only. Never a custom
  rating UI, never a "enjoying the app?" pre-prompt — double-asking is the
  pattern Apple's own guidance warns against, and it is beneath this app.
- **Never while it matters.** No prompt while an episode is live or recently
  live (no contraction recorded in the last 7 days), never on first launch,
  never adjacent to the closure flow's acknowledgment moment (per §1 — the
  moment labor ends is not a marketing opportunity), never from a lock-screen
  surface.
- The natural eligible moment is the calm *before* the night: the user has
  installed early, explored, set her rule, has zero or few recorded
  contractions, and is on at least her third session across at least three
  days. One request per install, tracked in local defaults; the OS caps it
  further and may not show it at all.
- A passive, user-initiated "Rate on the App Store" link lives in Guidance
  beside Support — always available, never pushed.

### 3. Diagnostics: Apple's channels, user-initiated reports, no analytics

OD-2 ("no analytics for v1") extends to Contractions, permanently sharpened by
the no-network promise. What we get without breaking it:

- **Apple crash reports, no code required.** Users who opted in to "Share with
  App Developers" surface crashes in Xcode Organizer / App Store Connect,
  symbolicated, with device and OS breakdowns. Opt-in rates run maybe a
  quarter to a third of devices — enough to see any crash that matters at
  scale, blind to rare ones. This is accepted, not worked around.
- **TestFlight**, while a build is in beta: crashes plus attached tester
  feedback and screenshots, the richest channel we will ever have. Use it
  deliberately before each release.
- **MetricKit** (`MXMetricManager` subscriber): the OS delivers crash and
  hang diagnostics *to the app, on device*. The app stores the last few
  payload summaries locally and transmits nothing.
- **A user-initiated "Report a problem"** path in Guidance → Support: composes
  a `mailto:` (same interaction class as `tel:` — the OS app does the sending,
  the user sees and sends the message). The body carries a diagnostic block
  the user can read and delete: app version, iOS version, device model,
  selected rule, and coarse shape (episode count, record count, whether a
  Live Activity was active). **Never contraction timestamps, durations, or
  history** — labor data is hers; if a specific bug needs it, we ask her in
  the reply and she decides.
- **`os.Logger` breadcrumbs** on the paths that have failed before (Live
  Activity lifecycle, store open, intent execution), so a sysdiagnose or a
  targeted question is answerable. Log content follows the same rule: state
  transitions, never her figures.

What this stance accepts, with eyes open: no usage funnels, no remote logs, no
visibility into non-crash misbehavior unless a user tells us. The mitigation is
not telemetry — it is the QA harness (decision 0021), which exists precisely so
correctness is proven before shipping rather than observed after.

## Consequences

- SP-215 (closure), SP-216 (review prompt), SP-217 (diagnostics) implement
  against this entry; their copy reviews check against §1 explicitly.
- The privacy manifest and review notes remain truthful without edits: the app
  still makes no network call in any of the above.
- If a future need genuinely requires analytics, that is a new numbered
  decision superseding this one and OD-2 — not an SDK slipped into a fix.
