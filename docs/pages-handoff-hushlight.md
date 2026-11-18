# Handoff — publish the Hushlight privacy and support pages

*Prepared 2026-08-27. Self-contained: everything an agent needs to build these
pages is in this file. The canonical sources live in the Hushlight repo
(`docs/privacy-policy-hushlight.md`, `docs/support-hushlight.md`); if this file
and the repo ever disagree, the repo wins.*

## The job

Build and publish two static pages on **christianwainright.com** so that these
exact URLs return the content below over HTTPS with a 200 status:

| URL | Page |
|---|---|
| `https://christianwainright.com/hushlight/privacy` | Privacy policy |
| `https://christianwainright.com/hushlight/support` | Support |

An iPhone app called **Hushlight** — a contraction timer for people in early
labor — links to these two URLs from inside the app, and they are the Privacy Policy
URL and Support URL fields of its App Store listing. Apple's review team will
visit both before the app can be approved. Nothing else on the domain is part of
this job.

## Hard requirements

1. **The exact paths above must resolve.** A redirect to a canonical form
   (trailing slash, `.html`) is fine as long as the final response is 200.
   No auth wall, no interstitial, no geo-blocking.
2. **Content must be readable without JavaScript.** App Review and expectant
   parents both deserve plain HTML that just renders. Static files preferred.
3. **The pages must live by the promise they describe.** The privacy policy
   says the app collects nothing — a policy page that itself sets tracking
   cookies or loads third-party analytics would contradict its own first
   paragraph. Therefore: **no analytics, no trackers, no third-party scripts,
   no fonts fetched from third-party CDNs, no cookie banner** (easy, because
   no cookies). First-party assets only.
4. **Do not rewrite the copy.** The content below is canonical and was written
   under the app's voice rules (calm, numerate, no fear language, no emoji, no
   exclamation points, no medical claims). Typographic conversion to HTML is
   the whole job. If something seems wrong, flag it back rather than editing.
5. **Readable on a phone.** These pages get opened from an app link at 3am.
   Modest measure (~65ch), generous line height, honest text scaling
   (relative units, no fixed heights), works in light and dark.
6. **No red anywhere in the design.** The app's brief bans it — the app never
   shouts. Neutral or warm-amber accents fit the brand; restrained is right.

## Design guidance (soft)

Minimal. System font stack is fine. A single column, the page title, the text.
No hero images, no nav chrome beyond perhaps a small "Hushlight" wordmark or
plain text header, no footer clutter. If the site has an existing layout,
inherit it — these are ordinary content pages, not landing pages.

Convert the two markdown documents below faithfully: headings to `<h1>/<h2>`,
bold to `<strong>`, lists to lists. Add two links the markdown implies:

- On the **support** page, "See the privacy policy" (in the backups answer)
  links to `/hushlight/privacy`.
- On the **privacy** page, it is worth a single line at the end linking back to
  `/hushlight/support` (e.g. "Support: christianwainright.com/hushlight/support")
  so each page reaches the other. Optional; nothing else may be added.

The contact address on both pages is **christian@wainright.net** — the email
domain is unchanged and is not a typo. `mailto:` links are fine.

## Acceptance checklist

- [ ] `curl -sIL https://christianwainright.com/hushlight/privacy` ends in 200
- [ ] `curl -sIL https://christianwainright.com/hushlight/support` ends in 200
- [ ] Valid HTTPS certificate for christianwainright.com
- [ ] Both pages render fully with JavaScript disabled
- [ ] Zero third-party requests on either page (check the network tab)
- [ ] No cookies set by either page
- [ ] Legible at iPhone width and at 200% text zoom
- [ ] Copy matches this document verbatim (headings, em dashes, bold intact)

---

## Addendum, 2026-09-06 — the localized pages, and one defect in them

The pages exist far beyond this document's original scope: both `privacy` and
`support` now answer under a locale segment for **37 App Store storefronts**
(`/hushlight/de-DE/privacy`, `/hushlight/ja/support`, and so on), with English still
at the bare paths. Verified live on 2026-09-06 — every locale the listing needs
returns 200, the copy is genuinely translated, and an unregistered locale 404s rather
than falling through to a catch-all. Nothing below changes that; it is recorded here
so the next reader does not think this file still describes two pages.

**The app follows the locale segments as of HL-052.** `LaborKit/PolicyLinks.swift`
maps the language the app resolved to onto the segment, and falls back to the bare
English path for anything it does not recognise — because an unregistered segment 404s
here rather than serving English, a guess would be worse than the fallback. Every URL
that mapping can produce (eleven segments × two pages) was verified live. If a locale
segment on the site is ever renamed or retired, that file is what has to change with
it.

**One defect, and it is worth fixing before submission (backlog HL-050).** Every
localized page serves its translated copy under `<html lang="en">`:

```html
<!-- /hushlight/ja/privacy today -->
<html lang="en">     <!-- ...with Japanese copy inside -->
```

VoiceOver chooses its speech synthesizer from that attribute. A blind reader opening
the Japanese privacy policy gets Japanese text read aloud by an English voice, which
is not merely wrong-sounding but largely unintelligible. Search engines use the same
attribute to decide which index a page belongs in.

- [ ] Each localized page sets `lang` to its own locale — `<html lang="ja">`,
      `<html lang="de">`, `<html lang="zh-Hans">`, `<html lang="pt-BR">` — and the bare
      English paths keep `lang="en"`
- [ ] The two pages an App Store reviewer opens for a given storefront are checked in
      that storefront's own locale, not only in English

This matters more here than it would elsewhere: the app itself spends real effort on
VoiceOver — every figure carries a spoken pair, and the mono-caps instrument words
have spoken forms precisely so a screen reader does not spell them out. Pages that
undo that at the door are the wrong first impression for exactly the reader who
benefits most from the rest.

---

## Page 1 · `/hushlight/privacy`

Everything between the markers is page content, verbatim.

<!-- BEGIN PAGE CONTENT -->

# Privacy Policy — Hushlight

*Last updated: 24 August 2026*

## The short version

Hushlight collects nothing, sends nothing, and has no account. Everything you
record stays on your iPhone.

That is not a promise about our intentions. The app has no network capability at
all — no code in it can make a network request, and there is no analytics
service, no advertising, no third-party software of any kind inside it.

## What the app stores

Only what you tap:

- **The time each contraction started and ended.** That is the entire record —
  two timestamps and an internal identifier. There is no name, no due date, no
  notes, no intensity rating, and nothing identifying you.
- **A few preferences:** which guideline you selected (5-1-1, 4-1-1 or 3-1-1),
  whether you have already seen the "How it works" card, and — only if you typed
  one in — your provider or labor-and-delivery phone number.
- **If the app ever crashes or freezes: a short technical note about it.** iOS
  hands the app a diagnostic, and the app keeps the last five summaries (what
  kind of problem, when, which version) so you can mention them if you write to
  us. They never contain your contraction times, and they are never sent
  anywhere. See "Crashes and diagnostics" below.

All of it is written to storage that belongs to the app on your device. No other
app can read it, including any other app we make.

## What the app does not do

- No account, no sign-in, no email address.
- No network requests. Nothing is uploaded, synced, or shared.
- No analytics, no advertising, no tracking of any kind. There is no
  crash-reporting service inside the app — see "Crashes and diagnostics" below.
- No access to Health data, contacts, location, camera, microphone, or photos.
- No notifications.
- No data is ever sold, and there is nobody to sell it to.

## Crashes and diagnostics

If the app ever crashes, iOS itself keeps a short technical summary on your
phone, and the app stores the last few of those summaries locally so a problem
is explainable if you choose to write to us. They never contain your contraction
times, and the app never sends them anywhere.

Separately, Apple offers every iPhone a setting called Share With App
Developers. If you have it turned on, Apple — not the app — passes crash reports
to us through its own system. Your recordings are not part of them, and the
setting is yours to change at any time in iOS Settings › Privacy & Security ›
Analytics & Improvements.

**Report a problem**, on the app's Guidance screen, drafts an email in your mail
app. Everything it contains is visible before sending and every line can be
deleted: app and iOS versions, your device model, your chosen guideline, and how
many contractions are recorded — never the times themselves. Nothing is sent
unless you send it.

## iCloud and backups

The app does not use iCloud. It has no iCloud capability and stores nothing in
any cloud database.

If you have iPhone backups turned on, your contraction records are included in
your device's backup the same way every app's local data is — that backup is
made and encrypted by Apple, under your control, and we never see it. You can
exclude it by turning off backups for the app in iOS Settings.

## Deleting your data

Two ways, both immediate:

- **Clear All History** at the bottom of the History screen removes every record.
  It asks first, and it cannot be undone.
- **Deleting the app** removes everything with it.

There is nothing to request from us, because we do not have anything.

## Children

The app is not directed at children and collects no data from anyone.

## Changes

If this policy ever changes, the updated version will be posted here with a new
date. Since the app collects nothing, the realistic reason for a change is a new
feature — and if one ever sends data anywhere, that will be stated here plainly
and before it ships.

## Contact

Questions about privacy, or anything else: **christian@wainright.net**

<!-- END PAGE CONTENT -->

---

## Page 2 · `/hushlight/support`

Everything between the markers is page content, verbatim.

<!-- BEGIN PAGE CONTENT -->

# Hushlight — Support

*A contraction timer that works offline, costs nothing, and keeps your data on
your phone.*

## How to use it

**Tap the bar at the bottom when a contraction starts. Tap it again when it ends.** That is
the whole job. Everything on the screen builds from those two taps.

- **INTERVAL** is measured start to start — the clinical standard, and the
  measure your provider will ask for.
- **DURATION** is how long each contraction lasts.
- **PATTERN** is how long the current stretch has been going.

The app shows a figure only once it has enough contractions to mean something. An
em dash means "not enough yet," never zero.

## The guideline

The chip at the top shows which guideline the screen is measuring against —
5-1-1 by default, with 4-1-1 and 3-1-1 available under Guidance, because
providers instruct differently. When your pattern meets the one you selected, the
app says so and suggests calling your provider.

**It never tells you that you are in labor, and never tells you not to go.** It
measures, reports, and defers to your provider's instructions.

## Things that do not wait for a timer

Call your provider right away, whatever the app shows, if your water breaks, you
have bleeding, you notice reduced fetal movement, or contractions begin before 37
weeks.

## Common questions

**Does it work without internet?** Always. There is no network code in the app.

**Do I need an account?** No, and there isn't one to make.

**I forgot to tap when it ended.** Any contraction over three minutes is flagged
`CHECK · OVER 3 MIN` and left out of the duration average, so one forgotten tap
doesn't distort your figures. Delete it from History if you want it gone.

**I tapped by mistake.** Undo is in the History toolbar and takes back the last
action. You can also swipe any row to delete it.

**The lock screen timer disappeared.** iOS ends a lock-screen Live Activity after
eight hours. Open the app and it comes back — your contractions were never
affected, only the lock-screen shortcut.

**Will it work on my iPad or Apple Watch?** Not yet. iPhone only for now.

**Is my data backed up?** Only inside your normal iPhone backup, if you have one.
See the privacy policy.

## Contact

**christian@wainright.net** — questions, bug reports, or anything the app got
wrong. If you are reporting a problem, the app version is in Settings under
General → iPhone Storage → Hushlight.

<!-- END PAGE CONTENT -->

---

## When the pages are live

Tell Christian, and note it against Hushlight backlog item HL-005 and the
"Host the two pages" line of `docs/submission-checklist-hushlight.md`. Nothing
in the app changes — it already links to these URLs.
