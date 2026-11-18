# Submission checklist — Hushlight

Everything below needs Christian's Apple ID or his judgment. CLAUDE.md's second hard
gate covers all of it: *credentials and releases*. Nothing here is agent work.

**Prepared and waiting:** privacy manifests (both bundles), export-compliance answer,
policy and support copy, review notes, listing draft, icon with appearance variants,
seven framed 6.9" screenshots and two app previews (HL-037).

---

## Before App Store Connect

- [x] **HD-1 closed 2026-08-27: the name is final.** The knockout ran against USPTO's
      Trademark Search (TESS itself is retired), and it moved the evidence before the
      call was made. The nearest mark is no longer "a class 7 filing" — it is a **live
      registration**: HUSHLIGHT, serial 99439100, Reg. 8252886, filed 2025-10-12,
      registered on the Principal Register 2026-05-12, IC 007 (wood splitters; standby
      electric generators), owner Foshan guangyuisuixing cross-border E-commerce Co.,
      Ltd. A second identical-string record (serial 97863773, IC 020) is dead. **The
      app's own classes are clear:** nothing for `hushlight` or `hushlite` among live
      marks in 009 and its coordinated set (010, 016, 028, 035, 038, 041, 042, 044); a
      broad `hush` sweep of live class 009 returns 120 marks, none light-adjacent.
      Identical string, unrelated goods, different owner — Christian accepted the risk
      with those facts in hand. **This is not a clearance opinion and no attorney was
      engaged.** The practical exposure, named at the time: a registrant can complain to
      Apple and Apple can act on a listing without anyone going near a court. Reserving
      the name in App Store Connect is what actually holds it, and that waits on HD-2.
- [x] **Host the two pages** at the URLs the app already links to — the app ships with
      these hard-coded (`GuidanceScreen`), so they must resolve before review:
      - `https://christianwainright.com/hushlight/privacy` ← `docs/privacy-policy-hushlight.md`
      - `https://christianwainright.com/hushlight/support` ← `docs/support-hushlight.md`
      *(live and accepted 2026-09-05 — every check in `docs/pages-handoff-hushlight.md`
      run against the live pages: apex 308s to `www`, both end in 200; Let's Encrypt
      certificate valid to 2026-11-09; every request on both pages is same-origin, zero
      third-party hosts, no cookies; content is server-rendered so it reads with JavaScript
      off; copy matches the handoff verbatim, em dashes and bold intact; legible at 375 pt.
      One prose drift found and left for the site: the privacy page says "Clear All
      History at the bottom of the History screen" — it is the toolbar menu, and the
      button reads "Clear Everything". Not a review risk; the same class as F-0058.)*
- [x] **Use the app through a full night on a device.** A1's exit gate asks for an app
      trusted through a whole night, and no amount of simulation substitutes.
      *(2026-09-05: completed. Recorded as reported — no agent verified this and none
      could; that is the whole point of the gate.)*

## In App Store Connect

- [x] Create the app record; bundle id `net.wainright.hushlight`. The old
      `net.wainright.setpoint.contractions` id was never registered, so nothing is
      stranded — but a bundle id cannot be changed after the record exists, so this is
      the step HD-1 actually gates.
- [x] **Regulated medical device status: No.** Required for US/UK/EEA since March 2026.
      One click, but the app cannot distribute in those regions without it.
- [x] **App Privacy: Data Not Collected**, every category, no exceptions.
- [x] Category **Medical** (primary). See the listing draft's note — Health & Fitness is
      the alternative; Medical is the honest shelf and draws more §1.4.1 scrutiny, which
      the non-diagnostic copy is written to survive.
- [x] **Age rating 12+**; medical/treatment information *infrequent*. This line used to
      say 4+ *and* infrequent, which Apple's matrix does not allow — Infrequent/Mild
      produces 12+, None produces 4+. Christian chose 12+ on 2026-08-28: the app ships a
      call-right-away card naming bleeding, reduced fetal movement and preterm
      contractions, and calling that "no medical information" to buy a 4+ is the kind of
      claim a Medical-category review is built to catch.
- [ ] Price: **Free**. No IAP target exists.
- [x] Privacy policy URL, support URL, copyright — from the listing draft.
- [ ] **Replace the five raw screenshots with the seven frames** in
      `docs/design/hushlight/store/frames/` (6.9" slot, in file order) and add the two
      previews from `docs/design/hushlight/store/previews/` (HL-037, 2026-09-05). The
      previews autoplay first in the gallery; pick the poster frame on each after upload
      (a-two-taps: the verdict around 17 s; b-lock-screen: the lock screen around 12 s).
- [ ] **iPad (from 1.1, HL-058c):** the two frames in `docs/design/hushlight/store/frames-ipad/`
      go to the 13" iPad slot — the Listing workflow does this (`--screenshots`) once
      `TARGETED_DEVICE_FAMILY` is "1,2" in the build under review; App Store Connect
      will not accept iPad screenshots on an iPhone-only build, and will not accept an
      iPad build without them.
- [ ] Paste **Notes for Review** from `docs/app-store-review-notes.txt` — the rendered
      text. Not from `Disclaimers.swift`: the source is a Swift literal with
      interpolation and continuations, so there is no verbatim to copy, and the
      unit test pins it against `neverSays` rather than against the UI it describes.
      It said "tap the large circle" for several items after the circle became a slab
      (F-0058). `./scripts/render-review-notes.sh` regenerates the file; the gate and
      a LaborKit test both fail while it is stale, so a green build means the file is
      current. Re-read it whenever a control is renamed or reshaped.
- [ ] Confirm no export-compliance prompt appears (answered in the plist).

## Build and submit

**Either archive by hand in Xcode (below) or run the Release workflow — not both.**
`.github/workflows/release.yml` does the same steps on CI: archive, verify both privacy
manifests are actually in the archive, export, **validate**, upload. It is
`workflow_dispatch`-only and it uploads *only* — TestFlight promotion and submitting for
review stay here, in App Store Connect, by design.

Before its first run, five secrets have to exist as **environment secrets on
`appstore`** in `christianwainright/hushlight` (Settings → Environments → appstore —
not repository secrets; decision 0067). Every run waits for the environment's
approval. Only Christian can create these:

| Secret | Where it comes from |
|---|---|
| `ASC_KEY_ID` | App Store Connect → Users and Access → Integrations → App Store Connect API. The 10-character Key ID. Give the key **App Manager** — Developer cannot upload builds. |
| `ASC_ISSUER_ID` | Same page, top. A UUID shared by every key on the account. |
| `ASC_KEY_P8_BASE64` | `base64 -i AuthKey_XXXX.p8 \| pbcopy`. The .p8 downloads **exactly once**; there is no second chance. |
| `DIST_CERT_P12_BASE64` | Apple Distribution certificate exported from Keychain Access as .p12 *with its private key*, then `base64 -i cert.p12 \| pbcopy`. |
| `DIST_CERT_PASSWORD` | The password set when exporting that .p12. |

The job declares `environment: appstore`, so a required reviewer can be attached there
if a second deliberate click before an upload is wanted.

**The build number is an input, and it is spent once used.** App Store Connect rejects a
repeat, so every upload takes a higher number than anything already sent, whatever the
version. **Spent so far: 1.0 (1)–(5).** 1.1 (6) has not uploaded — two archives failed before
reaching App Store Connect (HL-068) — so the next upload is still 6.

- [x] Archive **Release** in Xcode and **validate** in Organizer — validation is where
      ITMS-91053 surfaces, so it is the real test of the privacy manifests.
- [x] Confirm both manifests are in the archive:
      `Hushlight.app/PrivacyInfo.xcprivacy` and
      `…/PlugIns/HushlightWidgets.appex/PrivacyInfo.xcprivacy`.
- [ ] TestFlight first if wanted (SP-083 exists for external testers).
- [x] Submit. *(Christian, 2026-09-05: submitted for review. **The build under review is
      1.0 (2), archived from `650db83`** — which predates the HL-042 icon by thirteen
      minutes, so it carries the previous artwork. It also predates HL-044's How It Works
      bar fix and HL-043's latch work. See the warning under "Known, accepted".)*
- [ ] Tag the shipped commit `hushlight-v1.0` (decision 0020). **Tag `650db83`, not
      `main`** — decision 0020 wants any binary in the wild to map to a commit, and the
      binary in the wild will be 1.0 (2)'s. Tagging the tip would point the version at
      code that never shipped. Waits for release, not submission.

## Crash reports and diagnostics (decision 0029 §3)

The app collects nothing, so every diagnostic channel is Apple's or the user's own:

- [ ] **TestFlight before each release** — the richest channel there will ever be:
      crashes plus tester feedback and screenshots. Use it deliberately.
- [ ] **After release, check Xcode Organizer ▸ Crashes/Hangs** (and App Store
      Connect ▸ Metrics) on whatever cadence feedback suggests. Only devices with
      Share With App Developers on report — roughly a quarter to a third, with
      day-scale latency — so it sees any crash that matters at scale and misses rare
      ones; that trade is accepted, not worked around. dSYMs upload with the
      archive; nothing to configure.
- **MetricKit summaries stay on the user's device.** The app keeps the last five
  crash/hang summaries locally; a problem-report email carries their counts, and a
  reply can ask the user to read one out. Never ask for contraction data up
  front — if a specific bug needs it, ask in the reply and she decides.
- **A user's "Report a problem" email** (Guidance) carries versions, device, rule,
  and coarse counts. For anything deeper, the breadcrumb predicate against a
  sysdiagnose is `log show --predicate 'subsystem == "net.wainright.hushlight"'` —
  state transitions only, so there is nothing sensitive in it to redact.

## Known, accepted, and worth being able to answer

- **Live Activity ends at 8 hours.** Platform limit; decision 0028 declines to defeat it
  with push because that would cost the offline guarantee. Opening the app restores it,
  and a foreground past six hours replaces it pre-emptively.
- **Portrait only on iPhone.** Deliberate (decision 0018; HIG sanctions portrait-only
  explicitly). iPad takes all four orientations (decision 0064), and the app ships in
  nine languages.
- **Share and Copy exist, on the For the call card (SP-206).** This bullet said "no
  export/share" long after both shipped. Both are user-initiated — the system share
  sheet and the pasteboard — and the review notes name them beside Call and Report a
  problem, so a reviewer who taps Share does not find a route the notes denied.
- **F-0034** — 38 contrast findings on the local audit leg, untriaged; the first was
  disproven against sampled pixels, and the same tool demonstrably misreports
  `Font.body` (F-0032). Not a submission concern.
