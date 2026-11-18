# Reply to App Review — Guideline 2.1, Information Needed

Rejection received 2026-09-06 against **1.0 (2)**. It is the standard information request Apple
sends a developer account with limited review history — six numbered questions, no
defect alleged and nothing found wrong with the binary.

**Round 1 is history.** Its reply (§2) and notes went to Apple with 1.0 (5) and the
information request was satisfied; that block stays below as the record of what was
said, and its "WidgetKit" line is the one that produced round 2's 2.1(a). **Act on the
Round 2 section only:** paste its reply into **Reply to App Review**, paste the current
`Disclaimers.reviewNotes` (which no longer names WidgetKit) into **App Review
Information → Notes**, replace the two previews, and resubmit with 1.0 (5) unchanged.

---

## Round 2 — 2026-09-09: three findings, none of them in the binary

Reviewed on an **iPad Air 11-inch (M3), iPadOS 26.6.1**, against 1.0 (5). Nothing about
the build needs to change; all three are metadata, and two of them are things we handed
Apple ourselves.

| Guideline | What they found | What it actually was | Fixed by |
|---|---|---|---|
| 2.3.7 | Subtitle references price | Every one of fourteen subtitles led with "free" | New subtitles in all storefronts; "free" also removed from one screenshot caption and both preview cards (`a5`, `b5`); the lint now refuses a price word in the four metadata fields, the screenshot captions and the preview cards |
| 2.1(a) | "Unable to add Widgets" | The app is **iPhone-only** and has **no widget**; our review notes listed "WidgetKit" and the reviewer went looking for one on an iPad | The notes no longer name WidgetKit, say there is no widget, and tell the reviewer the Live Activity appears on the Lock Screen — on an iPad too, verified on an iPad Air 11-inch, behind the one-time Allow prompt |
| 2.3.4 | Previews contain device frames | They did — the previews were the framed screenshot brought to life | Both previews re-rendered full-bleed with text overlays only |

**What is yours this round:** paste the new Notes (`Disclaimers.reviewNotes`, changed),
paste the reply below, **delete the two old previews and upload the two new ones** in
App Store Connect (they are not in the repository and CI cannot upload them — see
HL-055), and resubmit with 1.0 (5) unchanged. The subtitle and screenshot changes go up
through the Listing workflow.

### Paste this into Reply to App Review

> Thank you for the further review. Responses to all three items:
>
> **Guideline 2.3.7 — subtitle.** The subtitle read "Free, offline, no account." It has
> been changed in every localization to remove the price reference; the English now
> reads "Private, offline, no account." We also removed the word "free" from one
> screenshot caption and from both app-preview text cards that carried it, so that no
> metadata surface refers to price. The description still says the app is free, which we understand to be the
> appropriate place for it.
>
> **Guideline 2.1(a) — Widgets.** We believe this was a misunderstanding caused by our
> own review notes, and we have corrected them. The app has no Home Screen widget. It is
> built for iPhone — it is a bedside timer — and its one app extension renders a Live
> Activity: the Lock Screen and Dynamic Island card shown while a contraction is being
> timed. Our notes listed "WidgetKit" among the frameworks used, because Live Activities
> are built on it; that line has been removed so it cannot suggest a widget exists. To
> see the Live Activity: tap Start, then lock the device; the card appears on the Lock
> Screen and can end the contraction from there. On an iPad the app runs in
> iPhone-compatibility mode and the card still appears — we verified this on an iPad
> Air 11-inch — after iPadOS asks "Allow Live Activities from Hushlight?" the first
> time, so please tap Allow. It is easiest to see on an iPhone, where the Dynamic Island
> shows it as well. There is no other extension and nothing to add to a Home Screen.
>
> **Guideline 2.3.4 — app previews.** Both previews have been replaced. The new versions
> are full-screen captures of the app with text overlays only; the device frame and the
> background behind it have been removed entirely.
>
> The build under review, 1.0 (5), is unchanged; all three items were resolved in the
> metadata.

## 1 · The screen recording — the one part that needs you

Apple asks for a recording **captured on a physical device running the latest OS**,
beginning with the app launching. A simulator capture does not satisfy it, so this is
yours to shoot. Two to four minutes is plenty.

**Turn on Airplane Mode before you start and leave it visible in the status bar.** It
costs nothing and it demonstrates the central claim of the whole listing in a way no
sentence can.

| # | Show | Why it is in the list |
|---|---|---|
| 1 | Home screen, tap the Hushlight icon | Apple requires the recording to begin at launch |
| 2 | The How It Works card on first launch, dismissed in one tap | Answers "is there onboarding?" — one card, no quiz, no account |
| 3 | The timer at rest: the button filling the lower half, the guideline chip | The app opens on the button |
| 4 | Tap Start, let it run ~40s, tap End. Repeat twice | The whole interaction. Show the em dashes *before* the floors are met — that is the evidence discipline, not a bug |
| 5 | Lock the phone mid-contraction; end it from the Lock Screen | The Live Activity, and why the phone need not be unlocked |
| 6 | History: the list, the episode band, swipe-delete, Undo | Records are editable and recoverable |
| 7 | The clipboard icon → For the call | What a provider actually gets read to them |
| 8 | Guidance: guideline picker, provider number field, the call-regardless card, the disclaimer, the policy links | Answers questions 3 and 6 visually |
| 9 | The met verdict and the Call button | The one state real time cannot reach — see the note below |

**Step 9 is why the build on your phone is a development build** (HL-054). The met
verdict needs an hour of sustained pattern *by design*, so it cannot be reached inside a
recording. The build installed on the device re-seeds a fresh 5-1-1 send-off **on every
cold launch**, so every take opens on the verdict and the Call button — rather than one
take being possible before the pattern ages out of it.

Two things follow, both in your favour. Force-quit and reopen between takes and you get
a clean met screen every time. And anything you tap during a take — Start, End, a
swipe-delete in History — is wiped by the next cold launch, so a fumbled take costs
nothing.

The reply says plainly that the recording comes from a development build with pre-filled
records. That is better than a recording which appears to show an hour passing in ninety
seconds, and it is true of the whole video, so it holds however much of it you shoot
this way.

Nothing else on Apple's sub-list applies and the reply says so: there is no account
registration, login or deletion flow, no user-generated content, and no paid content
or feature anywhere in the app.

---

## 2 · The round-1 reply, as sent (do not resend — see the top of this file)

> Thank you for the review. Answers to all six items follow, and the same information
> has been added to the Notes field of App Review Information.
>
> **1. Screen recording.** Attached, captured on a physical iPhone running the latest
> iOS, beginning at launch and following the typical flow: first launch and its single
> explanatory card, timing two contractions with the main button, the Lock Screen Live
> Activity ending a contraction without unlocking, History, the call-summary screen,
> and the Guidance screen with its guideline picker and reference card. The device is
> in Airplane Mode throughout, which demonstrates that the app is fully functional with
> no network of any kind.
>
> Three items on your list do not exist in this app, so they do not appear in the
> recording: there is no account registration, login or deletion flow; there is no
> user-generated content, and therefore no reporting or blocking mechanism to show; and
> there is no paid content or feature.
>
> The recording is made on a development build whose stored records are pre-filled
> with a completed stretch of contractions. The app reports that a pattern meets the
> selected guideline only once it has been sustained for about an hour — that is the
> guideline itself, not a delay — so that state cannot be reached inside a short
> recording. It is the same binary and the same code paths as the submitted build;
> only the timestamps already in the local database differ, exactly as they would
> after a real hour of tapping.
>
> **2. Purpose and target audience.** Hushlight is a contraction timer for the hours
> before someone leaves for the hospital or birth centre. The audience is people in
> late pregnancy and early labour, and the partner who is usually the one holding the
> phone.
>
> The problem is specific. A provider gives an instruction of the form "call when the
> contractions are five minutes apart, lasting about a minute, for an hour" — and at
> 3am, in a dark room, part-way through a contraction, there is no way to know whether
> that has happened without something keeping time and doing the arithmetic. The app
> takes two taps per contraction, computes the pattern, and reports it against the
> guideline the user selected. It is free with nothing to buy, it shows no
> advertising, it requires no account, and it works with the phone in Airplane Mode.
>
> **3. Setup and access.** Nothing is required. There is no account, no login, no demo
> credentials and no sample files. Launch the app and the timing button is on the
> screen; every feature is reachable from there without any setup. The single optional
> setting is a phone number for the user's own provider, typed on the Guidance screen,
> which enables the Call button; left blank, no Call button appears anywhere in the
> app.
>
> **4. External services, tools and platforms.** None. There is no data provider, no
> authentication service, no payment processor, no AI service, no analytics, no
> advertising SDK and no crash-reporting service. There is no third-party code of any
> kind — every Swift package the app builds is local to the project.
>
> The app contains no networking code at all: no URLSession, no Network framework, no
> sockets, and it declares no network entitlement. It makes no requests and behaves
> identically in Airplane Mode. It uses Apple frameworks only — SwiftUI and UIKit for
> the interface, SwiftData for a local on-device store, ActivityKit and WidgetKit for
> the Live Activity, AppIntents for the Lock Screen buttons, MetricKit, StoreKit, and
> os for logging.
>
> Two of those deserve a precise description, because each could be mistaken for
> something it is not. MetricKit is the operating system delivering crash and hang
> reports to the app on the device; the app keeps a local count and a short summary so
> that a user who chooses to email us can include it, and the app transmits it nowhere.
> StoreKit is present solely for the system "rate this app" prompt; there are no In-App
> Purchase products and no purchase API is called.
>
> The only way anything leaves the device is a tap the user makes: the Call button
> opens a tel: URL with the number she typed in herself, "Report a problem" opens a
> pre-filled mail compose window that she reads and sends or discards, and the privacy,
> support and rating links open Safari or the App Store.
>
> **5. Regional differences.** None. The app functions identically in every region.
> There is no geo-gating, no region-specific content and no server, so there is nothing
> that could vary by territory. It is localised into nine languages — English, Spanish,
> French, German, Italian, Brazilian Portuguese, Japanese, Korean and Simplified
> Chinese — and language changes the words only: every figure, threshold and verdict is
> computed identically whatever the locale, and the test suite asserts that. The three
> guideline options (5-1-1, 4-1-1, 3-1-1) are offered everywhere and are the user's own
> selection, never a regional default. The privacy and support links inside the app
> resolve to the page in the language the app is being read in, so a reader on any
> storefront reaches those documents in their own language.
>
> **6. Regulated industry and third-party material.** Neither applies.
>
> The app is not a medical device and makes no medical claim. It is a stopwatch with
> arithmetic: it measures what the user taps and reports what it measured. It does not
> diagnose, it never states or implies whether the user is or is not in labour, it
> predicts nothing, and it issues no instruction. When the measured pattern meets the
> guideline the user selected, it reports the measurement and says that calling her
> provider is reasonable — deferring explicitly to that provider's instructions, which
> the app states come first. A reference card lists what warrants a call regardless of
> any timer, such as water breaking, bleeding, reduced fetal movement, or contractions
> before 37 weeks.
>
> Intervals are measured start-to-start, which is the clinically standard frequency
> measure. "5-1-1" describes contractions about five minutes apart, each lasting about
> a minute, sustained for about an hour; 4-1-1 and 3-1-1 are the same shape at tighter
> spacing, offered because providers instruct differently. This is widely published
> general guidance rather than anyone's proprietary content, and the app presents it as
> the commonly used guideline it is.
>
> No licensed or protected third-party material is used anywhere in the app. Every word
> of copy, every illustration and the icon are original to it.

---

## 3 · Notes for Review

Apple asked that the same information go in **App Review Information → Notes** "for
reference on future submissions". Paste `Disclaimers.reviewNotes` — it is the single
source the app's own disclaimer is assembled from, so the notes and the shipped copy
cannot drift, and two tests hold it: one asserts it answers all five written questions
plus the three "there is none" sub-answers, and one asserts it fits inside the field's
4,000 characters, which it does with very little to spare.

## 4 · What was *not* alleged, and is worth not over-reading

No bug, no crash and no metadata problem was cited. The "Prevent Common Issues"
block at the foot of Apple's message is boilerplate appended to every 2.1 information
request; none of its bullets was raised against this submission. The one worth a
glance anyway is 2.3.3, which requires screenshots to show the app in use rather than
title art — ours are framed captures of real screens with a caption above, which
satisfies it.
