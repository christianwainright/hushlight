# App Store listing — Hushlight

Backlog SP-196. Drafted per the working agreements; **the listing needs Christian's
approval, and submission is a hard gate** (CLAUDE.md §Autonomy).

**Name:** *Hushlight* (decision 0033). HD-1 still holds the last human step — a TESS
knockout and reserving the name in App Store Connect — but the name is settled enough
to write against. If it ever moved, the substitutions are the title, the first
description line, and the two URLs.

**Positioning (SP-171):** the category incumbent onboards through fabricated urgency,
quiz-gates the timer, loss-frames, runs banner ads under the labor button, and prints an
average from two intervals. Our copy is the inversion, stated plainly. **Do not name the
competitor; describe ourselves.**

---

## Title
> Hushlight - Contraction Timer

*29 of 30 characters, and the pattern the naming research applied to every candidate it
vetted. The brand token alone earns no search traffic — nobody types "hushlight" until
they have heard of us — so the title carries the category term, which is the field Apple
weights most heavily.*

## Subtitle (30 characters)
> Private, offline, no account.

*29 characters. The search term is not repeated here: Apple indexes the title, subtitle
and keyword field as one set, so a duplicated phrase buys nothing and this line is the
only place three differentiators fit.*

*This read "Free, offline, no account." until App Review round 2 (2026-09-09) rejected it
under Guideline 2.3.7: **a price reference — and "free" is one — is not permitted in the
name, subtitle or keywords.** It is welcome in the description, which still opens on
"Free, forever." The differentiator that replaced it, "private", is the one the other
two were always in service of. `scripts/lint-store-metadata.sh` now refuses a price word
in any of the three fields, in every language, so this cannot come back.*

## Promotional text (170 characters, changeable without review)
> Opens on the button. No account, no ads, no network — it works in airplane mode.
> Times contractions and shows the pattern against the guideline your provider gave you.

*167 characters. "Works in airplane mode" is the cheapest possible proof of the privacy
claim and the one line no identity-linked competitor can copy; it earns its place here
by replacing "keeps it on your phone", which asserted the same thing without proving
it.*

## Description

*Two things this section used to get wrong, both found when HL-049 built the metadata
files that actually ship. **An App Store description has no formatting**, so the
`**bold**` headings would have shipped as literal asterisks; they are caps now, which is
what the eight translations already used. And **it preserves newlines**, so the source
wrapping below would have shipped as hard breaks in the middle of sentences —
`docs/store/metadata/<storefront>/description.txt` holds each paragraph on one line,
and those files, not this one, are what gets pushed.*


> A contraction timer that does one thing at 3am: tells you what your contractions are
> actually doing.
>
> Tap the bar when a contraction starts. Tap it again when it ends. That's the whole
> job — the rest builds from those two taps.
>
> FREE, FOREVER. NO ADS.
> Not a trial, not a subscription, not a free tier with the timer behind it. There is
> nothing to buy inside this app and nothing sold to anyone else.
>
> IT OPENS ON THE BUTTON.
> No quiz, no sign-up, no walkthrough standing between you and a contraction that has
> already started. A card explaining how it works is one tap away, once, and never
> again unless you ask for it.
>
> MEASURED THE WAY YOUR PROVIDER WILL ASK.
> Intervals are timed start to start — the clinical standard. You'll see how far apart
> they are, how long they last, and how long the pattern has held, against the guideline
> you selected: 5-1-1, 4-1-1, or 3-1-1.
>
> IT WON'T GUESS.
> No figure appears until there's enough timed to mean something — an em dash, never a
> zero, and never an average built from two intervals. If you forget to tap the end, that
> contraction is flagged and left out of the averages instead of quietly distorting them.
>
> BUILT FOR A DARK ROOM AND ONE HAND.
> The button is the whole lower half of the screen. Start and stop from the Lock Screen
> without unlocking. Full support for larger text and VoiceOver, because the middle of
> the night is when accessibility settings matter most.
>
> EVERYTHING STAYS ON YOUR PHONE.
> No account, no analytics, no network code at all. Your contractions are two timestamps
> each, stored on your device, deletable whenever you want.
>
> A stopwatch with arithmetic. It measures contractions and reports the pattern against
> the guideline you chose. It does not diagnose labor, and it is not medical advice —
> your provider's instructions always come first. When unsure, call.

*The closing paragraph is `Disclaimers.measuredNotDiagnosed` **verbatim**, not a
paraphrase of it. It had been a paraphrase — close enough to read the same and not the
same words — from the day this listing was written until `lint-store-metadata.sh` was
built for HL-049 and failed on its first run. The eight translated descriptions quote
their language's shipped disclaimer for exactly this reason, and English had no excuse
to be the one that did not: the sentence a reader is shown on the store page is now the
sentence the app shows them, in every language, checked.*

## Keywords (100 characters, comma-separated, no spaces)
> labor,labour,birth,pregnancy,doula,midwife,511,overdue,fullterm,newborn,surges,waves,tracker,counter

*100 characters exactly. "contraction" and "timer" are gone from this field, not
forgotten: they are in the title, and Apple's indexer treats the three fields as one
set, so repeating them here would spend a fifth of the budget to rank for nothing. The
four terms that replaced them are what the category's other apps are called and what
hypnobirthing users type instead ("surges"). Still deliberately excludes "medical",
"diagnosis", and any symptom term — the app claims none of them, and keywords are
metadata Apple reads as claims (§2.3).*

## Screenshots and previews

The set is `docs/design/hushlight/store/frames/` (HL-037): seven 1320×2868 frames, each a
raw capture framed on the Nightstand room with a headline in the voice. Both appearances
appear (3 and 6 light). The first two carry the listing in search results.

| # | Frame | Headline | Capture |
|---|---|---|---|
| 1 | `01-verdict` dark | When the pattern is there, it says so. | `-seedLabor511`, provider number set |
| 2 | `02-timing` dark | Start when it begins. End when it eases. | young seed, mid-contraction at 0:55 |
| 3 | `03-rest` light | Opens on the button. | `-seedLaborWipe` |
| 4 | `04-building` dark | It won't guess. | `-seedLaborYoung` |
| 5 | `05-lockscreen` dark | Start and stop from the Lock Screen. | Live Activity, locked |
| 6 | `06-history` light | Every stretch, kept on your phone. | History, 5-1-1 seed |
| 7 | `07-guidance` dark | Their guideline, their number, one tap away. | Guidance, wiped |

Two app previews, 886×1920, in `docs/design/hushlight/store/previews/` (rebuilt from the
`.edit` files; the `.mp4`s are not in git): **a-two-taps** (24.8 s — rest, Start, the
count, End, the verdict, the closing claim) and **b-lock-screen** (20.5 s — Start in the
app, lock, the count continues on the Lock Screen). Previews autoplay muted in search
results, so every beat is carried by the text card, not sound; both are silent with a
stereo AAC track present because the spec lists one. Upload order: previews first (they
lead the gallery), then frames 1–7. `docs/design/hushlight/store/README.md` has the recipe.

## Privacy nutrition labels
- **Data Not Collected** — every category. No exceptions, no linked data, no tracking.

*Verifiable rather than asserted: the app has no entitlements, no network code, and
no third-party packages. Its only logging is on-device os.Logger breadcrumbs of app
state transitions — event names from a closed set, never a recorded time (decision
0029 §3), so "Data Not Collected" stays a fact about the binary.*

## Review notes
Paste `docs/app-store-review-notes.txt` — the **rendered** text, ready to paste.

Do not paste from `Disclaimers.swift` directly, which is what this section used to say:
the source is a multi-line Swift literal with string interpolation and backslash
continuations, so there is no verbatim to copy. It has to be run. `app-store-review-notes.txt`
is the output of doing that — `./scripts/render-review-notes.sh` writes it, and both the
gate (`--check`) and a LaborKit test fail while it is stale, so it cannot silently lag the
source the way it did from 2026-09-05 to 2026-09-09.

**And re-read it when a control changes.** The notes are assembled from the app's own
strings and unit-tested, but the test pins them against `neverSays` — no diagnosis, no
instruction — which says nothing about whether the prose still describes the app that
exists. It did not: HOW TO TEST said "tap the large circle" for several items after
decision 0036 replaced the circle with a full-width slab (F-0058). Any decision that
renames or reshapes a control may have invalidated these notes, and nothing will fail.

## App Store Connect fields a plain app template omits
- **Category:** Medical — primary. (Health & Fitness is the alternative; Medical is the
  honest shelf for a labor timer, and both trigger the regulated-medical-device
  declaration either way.)
- **Regulated medical device:** No. Required for US/UK/EEA since March 2026.
- **Age rating:** 12+. Medical/treatment information *infrequent* — which is what
  produces 12+; 4+ would require answering *None*, and the call-right-away card makes
  that untrue. (This entry said "4+ … infrequent" until 2026-08-28, an impossible pair.)
- **Price:** Free. No IAP target exists.
- **Copyright:** © 2026 Christian Wainright
- **Privacy policy URL:** https://christianwainright.com/hushlight/privacy
- **Support URL:** https://christianwainright.com/hushlight/support
- **Marketing URL:** none.
- **Export compliance:** answered in the plist (`ITSAppUsesNonExemptEncryption = NO`);
  no prompt should appear.
- **Version / build:** 1.0 (1). Git tag `hushlight-v1.0` per decision 0020.
- **App icon in the store:** the dark ember artwork (`icon-1024-marketing.png`), not the
  light-appearance icon — decision 0035. The results row is the one place "a calm
  glowing thing in the dark" does acquisition work.

## Still needed before submission
- ~~HD-1: the knockout~~ — **closed 2026-08-27, the name is final.** Reserving
  *Hushlight* in App Store Connect still holds it, and that waits on HD-2.
- The two pages live at the URLs above (Christian hosts; content is written).
- Screenshots captured at 6.9" (Wave 5).
- App Store Connect record and the credentialed submission steps (Christian).
