# 0028 — The Live Activity cannot outlast the labor, so opening the app must always restore it

**Status:** accepted (found by the App Store readiness pass, 2026-08-17)
**Date:** 2026-08-17

## Context

ActivityKit ends a Live Activity eight hours after it starts. First labors routinely
run longer than that — often much longer — so the lock-screen button decision 0019
exists to provide will disappear partway through the night, in the middle of the use
case the whole feature was built for.

The data is never at risk. Running state derives from stored timestamps
(`Records.swift`: *"Running state lives here, in the store, never in a timer"*), so the
timer screen, the timeline, the averages and the verdict are identical whether an
activity exists or not. What disappears is the convenience surface: the reason she does
not have to unlock the phone mid-contraction.

Three defects made this worse than the platform requires:

1. Nothing observed `activityStateUpdates`, so the app could not tell a running
   activity from a killed one.
2. `hasActivities` counted a system-*ended* activity as present. ActivityKit keeps
   ended activities in `Activity.activities` until dismissal — up to four more hours —
   so `syncLiveActivity()` took its update branch and called `update()` on a dead
   activity. **Even opening the app would not bring the button back** during that
   window.
3. `StartStopContractionIntent` only ever updated existing activities; it had no
   create path.

## Decision

**The ceiling is a platform constraint an offline app cannot defeat.** Extending it
would need push updates, which need a network, which decision 0018 rules out and which
would trade the app's entire privacy story for a lock-screen convenience. We do not
try. Instead:

1. **Opening the app always restores the lock screen.** `hasActivities` filters on
   `activityState`, so an ended-but-not-yet-dismissed activity no longer blocks a fresh
   request. This is the fix that matters: foregrounding is the one moment we are
   guaranteed to run.
2. **Foregrounding re-arms an activity that is nearing its ceiling.** If the live
   activity has been running longer than six hours, it is ended and replaced. Someone
   in labor opens the app to look at the pattern; every time she does, the clock
   resets, and in practice that covers a labor far longer than eight hours without a
   single network call.
3. **The content carries a `staleDate`.** Set to the episode-gap horizon, so if the app
   somehow stops updating, the lock screen shows its figures as out of date rather than
   presenting stale numbers as current — the same honesty the in-app dating from
   decision 0022 provides.
4. **The intent gains a create path**, so any future entry point that can run it — an
   App Shortcut, the Action button — starts an activity rather than silently no-opping.
5. **The app says nothing about any of this.** No banner, no explanation, no "your
   lock screen timer ended" notice. HIG is explicit that apps should not teach people
   how the system works, and a woman in labor is the last person who should be handed
   an explanation of ActivityKit's lifecycle. It re-arms silently or it does not; both
   are quiet.

## Boundaries

No push capability, no background modes, no notification permission — the capability
list stays exactly as decision 0018 left it, which is the privacy story. If a future
version wants coverage while the app is never opened, that is a network conversation
and a different decision.

## Alternatives rejected

- **Tell the user the lock screen timer expired.** Explains a platform limitation to
  someone who is having contractions, and the actionable content is "open the app",
  which is what she just did to read the message.
- **A background task to re-arm.** Not reliably scheduled, and it would add a
  background mode to a capability list whose emptiness is the point.
- **Push-updated activities.** Defeats the offline guarantee outright.
- **Re-arm on every foreground regardless of age.** Churns the lock screen and
  restarts the elapsed-time rendering for no benefit; six hours leaves a wide margin
  under the ceiling while leaving short sessions untouched.
