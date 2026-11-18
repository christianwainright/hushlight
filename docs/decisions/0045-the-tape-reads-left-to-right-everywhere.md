# 0045 · The tape reads left-to-right everywhere, because it is an instrument

**Date:** 2026-08-25 · **Item:** HL-009 · **Status:** decided

## Context

HL-009 mirrors the app for right-to-left locales, and one element cannot take the
easy answer. The ember tape's axis is time — bars marching toward NOW at the right
edge — and a blind `leading`/`trailing` mirror would have time flow right-to-left
for an Arabic or Hebrew reader. Text should mirror. Should the instrument?

## Decision

**The tape's time axis is fixed: past on the left, NOW on the right, in every
locale.** So is the reading direction of the trace it imitates. The end caps
translate ("NOW" becomes the locale's word) but keep their positions. The vertical
episode timeline is direction-neutral and needs no ruling. Everything else on every
screen mirrors normally — layout uses `leading`/`trailing` semantics exclusively,
and any `.left`/`.right` literal is a defect.

## Rationale

The tape is not prose; it is the app's rendering of a **tocograph strip** — the
instrument every labor ward already prints — and strip-chart recorders, ECG traces,
audio waveforms and video scrubbers run left-to-right in RTL locales worldwide.
An Arabic-speaking midwife reads the same CTG strip a Dublin midwife does. Making
this one chart mirror would make the app's tape *disagree with the paper one on the
monitor beside it*, for the reader least served by novelty at 3am.

The same ruling already exists in miniature: mm:ss numerals and the mono-caps
instrument vocabulary are locale-invariant (HL-007's documented line). The tape is
that vocabulary drawn as geometry.

> **Narrowed by decision 0062 (2026-09-05).** The invariance this paragraph relies on
> is real and this decision is unchanged — the numerals, the monospaced face and the
> left-to-right direction all hold. But the sentence was read, elsewhere in the
> codebase, as also meaning the mono-caps *words* stay English, and it never said
> that. `NOW` and `APART` are now translated; the tape still runs left to right and
> still prints ASCII digits. See 0062 for why the wider reading had no decision
> behind it.

**Rejected: mirroring with the locale.** Consistency with the rest of the UI is a
real argument, and it loses to consistency with the clinical instrument the reader
will actually be handed. A mirrored tape is also a silently *different* chart in
screenshots shared between partners with different device languages — the same
record reading in opposite directions on two phones in one labor room.

## Boundaries

Fixing the axis is not an excuse to hard-code layout: the tape still sizes and
positions by geometry, not by `.left`/`.right` alignment, and its container mirrors
with the screen while the drawing inside holds its axis. Type fallback for scripts
SF Rounded and New York do not cover is HL-009's other half and carries no ruling
here beyond: name the fallback explicitly, never let the system pick per screen.
