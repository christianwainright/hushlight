# 0024 — Frequency is a share, not a mean

**Status:** accepted (findings F-0008, F-0012 — coupling defeats the mean)
**Date:** 2026-08-16

## Context

`frequencyMet` compares the windowed *mean* interval to the rule threshold.
Coupled back-labor arrives in pairs — alternating ~2 and ~8 minute gaps whose mean
is exactly 5:00. The mean is a value that never occurs; no clinician reads
2-and-8 as "every five minutes," and the median collapses to the same midpoint on
a perfect 50/50 alternation. The readout's whole-episode `lastInterval` beside the
windowed mean (20:58 vs 10:53) compounds the confusion on one row.

## Decisions

1. **`frequencyMet` becomes a share: at least two-thirds of in-window start-to-start
   intervals ≤ the rule's threshold** (minimum two intervals, as today). A textbook
   4:50 pattern passes at ~100 %; strict 2/8 coupling sits at 50 % and does not
   pass; an irregular-but-progressing labor whose spacing has genuinely tightened
   passes as soon as most of its gaps have. Two-thirds is the harness-calibrated
   point: the T1 paired sweeps show no measurable onset-lag cost on clean textbook
   streams and the false-met probes go quiet.
2. **The displayed average stays the mean** — "averaging every 4:50" is the figure
   providers ask for — but the INTERVAL column's detail slot becomes the in-window
   min–max range ("5:31–20:58"), a raw fact that makes bimodality visible instead
   of hidden inside a mean.
3. **`lastInterval` keeps its whole-episode definition** (the most recent gap is a
   raw fact) — with 0022's dating it no longer masquerades as current, and beside
   the new range it reads as the newest sample of a visible spread.

## Boundaries

Verdict copy keeps quoting the mean ("Averaging every {i}") — accurate, and now
backed by a share-based boolean that cannot be gamed by symmetry. LaborKitTests'
interval boundary cases move to share semantics (both sides), same commit.

## Alternatives rejected

- **Median interval.** Collapses to the mean on even-count alternation — fails the
  exact pattern that motivated the change.
- **Coupling detection + special-casing.** A second statistic with its own failure
  modes; the share handles coupling as a plain consequence, no pattern-matching.
- **Hiding the mean.** The figure is the provider conversation's vocabulary; the
  fix is a robust boolean plus a visible spread, not less information.
