# Contributing to Hushlight

Thanks for looking. Hushlight is small and opinionated. Reading this page before you
open a pull request will save us both a round trip.

## Lines that don't move

A pull request that crosses any of these will be closed, however good the code is:

- **No network.** No network capability, no remote Swift packages, no SDKs, no
  analytics, no crash reporters. CI fails the build on a remote dependency.
- **Nothing a user times leaves the device**, unless the user explicitly hands it
  off through Copy or Share.
- **Free forever.** No ads, no accounts, no purchases.
- **No fear language, and no diagnosis.** The app reports a pattern against the
  guideline the user chose. It never says *you are in labor*, and red is not in its
  palette. LaborKit's `Disclaimers` tests enforce the copy.

## Before you open a PR

```bash
./scripts/test.sh   # package tests
./scripts/gate.sh   # design-spec gates (literal colours and fonts, row figures, logging, …) and a build
```

- Define colours and fonts in `DesignKit` only. Call sites name a role, such as
  `.dataText(.hero)`, never a point size or a hex value.
- Changes to pattern analysis, verdict rules or aggregation need unit tests, and
  `./scripts/labor-sim.sh` must still pass.
- UI changes must hold up in light and dark, at the largest accessibility text size,
  and with VoiceOver labels. [`docs/design/DESIGN-SPEC.md`](docs/design/DESIGN-SPEC.md)
  §8 lists the gates.
- If a change makes a call that isn't obvious, a numbered entry in
  [`docs/decisions/`](docs/decisions/) is welcome. Don't reverse a numbered decision
  quietly: supersede it with a new entry.

## Medical content

The call-right-away card and the guideline copy are deliberately conservative
([decisions 0060 and 0061](docs/decisions/)). Changes to that copy need a source, and
ideally a clinician's read. Translations of the six safety-critical strings are held
to the same bar.

## Reporting a bug

Open an issue with the device, the iOS version and what you saw. Hushlight collects
no telemetry, so your description is the only report there is. Please don't attach
real contraction records unless you're comfortable with them being public.
