# 0062 · The instrument vocabulary translates

**Date:** 2026-09-05 · **Item:** HL-008 · **Status:** decided

## Context

The app's mono-caps words — `CONTRACTIONS`, `INTERVAL`, `DURATION`, `PATTERN`,
`APART`, `LONG`, `HOLDING`, `NOW`, `TOTAL`, `RUNNING`, `CHECK`, `SINCE`, `LAST … AGO`
— sit on the readout, the tape's end caps and the verdict's legs. They are the most
frequently read words on the primary screen.

Running the app in Spanish for the first time showed them still in English, and the
source said that was deliberate. `ForTheCallScreen` carried this:

> `"RUNNING"` stays a bare mono-caps literal on purpose: it is this line's own
> instrument flag word, the same register `CHECK · OVER 3 MIN` and `TOTAL` already
> keep bare elsewhere in this app (CLAUDE.md's instrument-vocabulary line, drawn once
> for the whole item).

**That citation does not resolve, and neither does the one behind it.**

- CLAUDE.md has no instrument-vocabulary line. Its only nearby rule is *"Data numerals
  are monospaced; prose is SF Pro."* — a typography rule that says nothing about
  translation.
- Decision 0045 says "mm:ss numerals and the mono-caps instrument vocabulary are
  locale-invariant (HL-007's documented line)", but it says it while arguing that the
  *tape must not mirror in RTL*. The invariance it needs is directional.
- The line it points at, in `Typography.swift`, is about **font fallback**: those
  glyphs "never leave their requested face, in any role, under any script". That is a
  guarantee about which typeface renders them, not about which language they are in.

So a policy was being enforced in code on the strength of a chain of citations that
never terminates in a decision. HL-006's own acceptance criteria point the other way:
it gives *"a bare `LAST` is untranslatable; 'elapsed time since the last contraction
ended, mono-caps column header' is not"* as its worked example of what belongs in a
catalog **with a comment**.

## Decision

**Christian's call, 2026-09-05: the instrument vocabulary translates.** Every one of
those words is now a catalog key with a translator comment naming both its meaning and
the fact that the caps are a type role, not content — so a translator supplies a word,
not capitals.

**What stays invariant is exactly what was ever really invariant:**

- **mm:ss and H/M numerals**, ASCII digits, and the `·` separators.
- **The monospaced face**, under every script — `Typography`'s guarantee is untouched,
  and it was never about language.
- **The tape's left-to-right direction**, including in RTL. Decision 0045 stands
  entirely: its argument is that the chart must agree with the paper instrument beside
  it, and translating a caption does not turn the chart around.

## Rationale

The counter-argument is real and was weighed: instrument markings are a register, and
a CTG strip says the same thing in every ward in the world. Two things beat it.

The reader. `INTERVAL`, `DURATION` and `PATTERN` are the three labels under the three
biggest figures on the screen, read by someone at 3am who chose Spanish because that is
the language she thinks in. An app that translates its prose and leaves its column
headings in English has decided the prose matters more than the numbers, which is the
opposite of what this app believes.

And the honesty of the record. A rule enforced by comments citing a rule that does not
exist is worse than either answer, because nobody can tell whether it was decided or
merely repeated. This entry ends that either way it went.

## Consequences

`ForTheCallScreen`'s comment has been rewritten to say what is actually true rather
than to cite the missing line, and it now points here.

**Fourteen keys were added to the catalogs** as part of this, and four glued sentences
became format strings — `"SINCE \(time)"`, `"SINCE YESTERDAY \(time)"`,
`"SINCE \(weekday) \(time)"` and `"LAST \(gap) AGO"` in the header, plus the Live
Activity's `"AVG … APART · …"` and `"LAST … APART · …"`. Those concatenations were
what HL-007 existed to remove and it had marked itself done; see HL-046 for the
accounting.

A translator note rides every one of these keys: **the caps come from the type role**,
so `NOW` is translated as the word "now" in the target language and the role renders
it. A translator returning `AHORA` and a translator returning `Ahora` both produce the
same pixels.
