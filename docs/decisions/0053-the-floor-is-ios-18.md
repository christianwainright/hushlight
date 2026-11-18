# 0053 · The floor is iOS 18, and it always could have been

**Date:** 2026-09-05 · **Item:** HL-038 · **Status:** decided

## Context

The app shipped its first upload with a deployment target of **iOS 27.0** — an OS in
beta, installed on approximately nobody. That floor was never chosen: it was
inherited from the Setpoint scaffold this app was extracted out of (decision 0033),
where it was set at project creation and never revisited. No decision entry claims
it, no feature asked for it, and nothing in the DoD ever checks it.

Christian caught it. The question he asked is the right one and it had never been
put to the code: **what actually requires iOS 27?**

## Evidence

Answered by measurement, not reading. The target was lowered and the compiler asked
to enumerate the damage, at 18.0, 17.0 and 16.0 in turn:

| Floor | What the compiler rejects |
|---|---|
| **iOS 27.0** | *nothing* — the codebase contains no iOS 27 API at all |
| **iOS 26.0** | *nothing* |
| **iOS 18.0** | one call: `.scrollEdgeEffectStyle(.hard, for: .bottom)`, iOS 26+, one line of `TimerScreen` |
| iOS 17.0 | the above, plus SwiftData's `#Unique` macro on `ContractionRecord` |
| iOS 16.0 | the above, plus **all of SwiftData**, plus Live Activities below 16.1/16.2 |

One line. The entire app, the widget extension, DesignKit and LaborKit compiled
clean at an iOS 18.0 target with that single modifier removed — 15k lines of shipped
Swift and one incompatibility. The 27 floor was costing the app roughly seven years
of installed base to buy a scroll-edge fade opt-out.

## Decision

**The deployment target is iOS 18.0**, in `project.yml` and all three package
manifests.

1. `.scrollEdgeEffectStyle` is guarded, not dropped. The modifier opts *out* of the
   automatic scroll-edge blend that iOS 26 introduced; below 26 there is no blend to
   opt out of, so on the older OS the modifier's absence **is** the `.hard` edge
   HL-007 asked for. `hardBottomScrollEdge()` in `TimerScreen.swift` carries the
   `if #available(iOS 26.0, *)`, and both branches honour "wraps and scrolls, never
   through it".
2. **iOS 18 rather than 17**, and the reason is hardware, not taste: iOS 17 and iOS
   18 support the identical device list (iPhone XS/XR and later). Dropping to 17
   buys not one additional phone — only users who declined an update — and costs
   `#Unique`'s uniqueness constraint on the record store. iOS 16 would genuinely add
   the iPhone 8 and X, and costs SwiftData entirely. Neither trade is worth making.
3. **The beta toolchain pin is gone.** `DEVELOPER_DIR=/Applications/Xcode-beta.app`
   in six scripts existed for exactly one reason — an iOS 27.0 target no shipping
   SDK could satisfy. The app now builds, tests and runs clean on the machine's
   stock Xcode 26.6. Package manifests drop from `swift-tools-version: 6.4` to
   `6.0`, which is what `.iOS(.v18)` needs and what a released toolchain can read.
4. Simulator selection is **newest available**, via one shared `scripts/newest-sim.sh`,
   replacing three separate hardcoded `-- iOS 27` filters. Those filters made every
   QA script unrunnable on a machine carrying only the shipping Xcode.

## Consequences

**SP-042a is resolved, not worked around.** The note in CLAUDE.md — app-target UI
tests abort at load locally, prove them on CI — described a runtime/SDK mismatch
that only existed because of the beta pin. `LocaleFormatUITests` now passes locally
on the iOS 26.4 simulator in 16.8 s. The AX5 gate no longer needs a macOS CI run to
execute at all.

**The design was never 26-only.** Verified by running the built app on iOS 26.4: the
ember palette, the tick tape, the em-dash absence rule, the opaque pinned slab all
render as designed. The app leans on DesignKit tokens and its own capsule button
styles rather than system glass, so there is nothing to degrade.

**What is still worth checking before submission.** The app has never been *seen*
below iOS 26. Nothing compiles differently, but `.background(.bar)`, `.toolbar`
chrome and sheet presentation all changed appearance across 26, and the DESIGN-SPEC
§8 gates have only ever been walked on 26+. That is a look, not a break, and it is
filed rather than fixed here under DoD §5.

## Rationale

A contraction timer is used once or twice in a life, at 3am, on whatever phone the
household already owns — frequently an old one, frequently a hand-me-down, and
frequently not the birthing parent's newest device. "Free forever, no account, works
in airplane mode" is the promise; an OS floor that excludes a 2019 iPhone is the same
kind of exclusion as a paywall, arrived at by accident instead of by choice.

The floor was never a decision. This entry makes it one.
