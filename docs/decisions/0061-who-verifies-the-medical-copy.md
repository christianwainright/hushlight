# 0061 · Who verifies the medical copy

**Date:** 2026-09-05 · **Item:** HL-008 (HD-4) · **Status:** decided

## Context

HD-4 asked two questions and had been open since 2026-08-23: **which languages**, and
**who verifies the medical copy in each**. The second is the one that mattered.
`VerifiedLanguages` was built before any translation existed so that no translation
could precede it — a language whose four load-bearing surfaces have not had a verified
read may not appear in `verified`, and `LanguageGateTests` fails the build if a catalog
carries a load-bearing translation for a language that list does not name.

The set's own doc comment calls adding a code **"HD-4's verifier signing their name."**

## Decision

**Christian's call: the agent translates, and he accepts that translation as the
verified read.** No separate native reviewer. Nine locales: en, es, fr, de, it, pt-BR,
ja, ko, zh-Hans.

**Recorded as his acceptance, not as an agent's signature.** The distinction is the
whole reason this entry exists. An agent that translates the disclaimer and then also
signs for the disclaimer has satisfied a gate with the thing that gate was built to
exclude — the same structure decision 0060 turned on hours earlier, and the same one
F-0038's un-validated elimination test turned on. `VerifiedLanguages` says so in its
own comment now, so the set cannot later be misread as "a native speaker checked
these".

## The concern, and how it was put

It was raised before the work started, with the shape of the gate made explicit: the
money gate HD-4 describes was sized for *translating an app*, and it is actually sized
for **reviewing six sentences per language** — 54 short strings across all nine
locales, since only six keys are load-bearing. Christian's answer was that he trusts the
translation and does not need anyone to sign for it. That is his to decide, it was
reaffirmed, and it is implemented as asked.

**The residual risk, stated plainly rather than buried.** For es, fr, de, it and pt-BR a
reader with some knowledge of the language can sanity-check the six load-bearing strings
against their English. For ja, ko and zh-Hans, the acceptance is trust in the
translation rather than an independent read. That is a real reduction in assurance
against a native reviewer, and it is the thing to revisit first if any of these
languages ever draws a complaint about tone or accuracy.

## What compensates for it

Not nothing, and worth listing because the gate is now one person's judgement:

1. **`neverSays` per language, cut for the idiom.** T0-14 greps the *shipped* copy of
   each language against phrases chosen for how that language would actually go wrong —
   including shapes English has no counterpart for, like `ya viene el bebé`,
   `赤ちゃんが生まれます` and `要生了`. `verify_lang.py` refuses to verify a language whose
   own banned phrases appear in its own shipped copy.
2. **The register rules are mechanical enough to check.** No imperative in any verdict;
   no diagnosis verb; no fear word. Those are greppable properties, not taste.
3. **`apply_lang.py` refuses on coverage or specifier mismatch**, so the failure mode
   left is a *wrong* translation, never a broken or missing one.
4. **The oracle is unaffected.** Every figure, floor and verdict is language-independent
   by construction (HL-007), and LaborSim still agrees with `OracleMath` at every probe.

## Consequences

HD-4 closes. HL-008 ships all nine locales.

If a native reviewer is ever engaged — for HL-010's store copy, say — the six
load-bearing strings per language are the thing to put in front of them, and that is
minutes of work rather than a translation contract. This entry is not an argument
against doing that; it records that shipping did not wait for it.
