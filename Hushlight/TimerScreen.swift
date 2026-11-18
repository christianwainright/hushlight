import DesignKit
import LaborKit
import SwiftUI

/// The app. One giant button — tap when a contraction starts, tap when it ends —
/// with the pattern read out above it. Built for one-handed use mid-contraction at
/// 3am: the button is the whole lower half of the screen, and nothing on this
/// surface requires precision or reading to operate.
struct TimerScreen: View {
    @Environment(LaborModel.self) private var model

    /// HL-003 slice 1: the circle's fixed diameter (216–280 pt, floored and roofed
    /// against `.body`) is gone. The slab has one floor and no roof — full width by
    /// construction, and tall enough for its content rather than content squeezed to
    /// fit a disc. 110 pt is the identity's own number
    /// (`docs/design/hushlight/`, Nightstand: "one full-width slab, minimum 110pt
    /// tall"), and it is a *minimum*: Dynamic Type grows the bar from here rather than
    /// clipping inside it, which is the whole fix for how "Start" used to render as
    /// "Sta / rt" against a diameter that had stopped growing.
    private static let slabMinHeight: CGFloat = 110

    /// The gap between stacked columns, scaled — not the flat `Metrics.space4` the
    /// side-by-side arrangement can afford.
    ///
    /// At AX5 an em dash sat 39 pt above its own label and 51 pt below the pair above
    /// it: a ratio of 0.76, which is close enough to equidistant that the dash belongs
    /// to neither column. The intra-pair gap is almost entirely the *value's* line box,
    /// which scales with `.title2`; a constant against a scaling term is a ratio that
    /// drifts with the type size. Scaled against the same style it holds near 0.5 from
    /// AX1 through AX5, and is unchanged where the layout already read correctly.
    @ScaledMetric(relativeTo: .title2) private var stackedColumnGap: CGFloat = Metrics.space4

    /// SP-188: the idle slab breathes and the counts roll. All of it sits behind
    /// this check — motion is polish, and polish must never cost someone who has
    /// asked the system for stillness.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Decision 0022 §5: at accessibility sizes the verdict leads and the readout
    /// reflows. The readout alone is more than a screenful there, and the met,
    /// one-short-of-floor and forty-five-minutes-stale screens were indistinguishable
    /// in the first screenful because the one sentence that separates them sat below
    /// the fold on all three.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// HL-058: which of the four layouts this window gets — see `LayoutRegime`.
    /// Read with the window's size in `body`; never the device idiom.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// HL-058b: the keyboard's commands arrive here and do what the tap would.
    @Environment(KeyboardIntents.self) private var keyboard
    /// Where the toolbar's links and the keyboard's ⌘J/⌘G both push (HL-058b): one
    /// path, so a key and a tap land on the same screen the same way.
    @State private var path: [Route] = []
    /// HL-061: the hinge's pose, owned here with everything else a regime switch
    /// could rebuild (decision 0064's boundary).
    @State private var isHalfOpen = false

    enum Route: Hashable {
        case history
        case guidance
    }

    /// SP-190: the reference card shows itself exactly once, then waits behind the
    /// toolbar's `?`. Standard defaults — whether this phone has seen the intro is
    /// this phone's business.
    @AppStorage("hasSeenHowItWorks") private var hasSeenHowItWorks = false
    @State private var isShowingHowItWorks = false

    /// The record an end-tap just closed, when it is too short to believe (SP-203).
    /// Held only long enough to offer the correction; see `slipStrip`.
    @State private var slip: Contraction?

    /// Bumped when the strip's Delete lands, so the fix is felt as a fix — the same
    /// `.levelChange` texture History's undo and swipe-delete use (SP-202).
    @State private var corrections = 0

    /// SP-215's off-ramp, behind the recap's "Clear the instrument" action — the
    /// same confirmation History's own Clear All opens, never a second dialog.
    @State private var isConfirmingClear = false

    /// SP-215's "Keep a copy" — the recap's own trigger for SP-206's export sheet,
    /// held here rather than inside the `@ViewBuilder` that draws the recap: a
    /// `@State` cannot live in a function.
    @State private var isShowingClosureKeepsake = false

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    /// **Is there more below the bar?** (HL-028, F-0048.)
    ///
    /// Three of the walkthrough's five lenses read content below the pinned slab at
    /// accessibility sizes as effectively invisible; the accessibility lens read the
    /// same frames as working exactly as decisions 0027 and HL-007 built them —
    /// content stopping cleanly at an opaque edge, nothing truncated, one scroll away.
    /// Both readings are right about what they measured, and the gap between them is
    /// the difference between *reachable* and *found*.
    ///
    /// What neither reading disputes is the cause: at rest there is no signal at all.
    /// iOS scroll indicators appear while scrolling and fade, so a reader who has not
    /// yet scrolled has nothing telling her the sentence continues — and at AX5 the
    /// opaque, hard-edged bar reads exactly like the bottom of the screen, because
    /// HL-007 deliberately made it stop being translucent.
    ///
    /// So this does not take a side; it removes the cause. A single chevron in the
    /// bar's own top edge, shown only while content actually remains below, gone the
    /// moment she reaches the end. Decorative and hidden from VoiceOver: a scroll
    /// position is not a fact about her labor, and VoiceOver navigates by element
    /// rather than by fold, so the reader who cannot see it never needed it.
    @State private var hasContentBelowFold = false

    /// Fades rather than appears, and so keeps its ~23 pt of the bar whether it is
    /// lit or not. Not a style preference — the cue lives *inside* the
    /// `safeAreaInset` it is a cue about, so a version that inserts and removes
    /// itself changes the very geometry the predicate above reads: the measured
    /// numbers went from `containerSize` 533 / `contentInsets.bottom` 224 to 556 /
    /// 201 the instant it vanished, which shifted the content 23 pt at exactly the
    /// moment she reached the end of it. (It could not oscillate — showing the cue
    /// only ever *reduces* the visible height, so the two states are each
    /// self-consistent rather than chasing each other — but a bar that twitches
    /// under the reader's thumb at the bottom of the scroll is its own small
    /// failure.) Reserving the space costs one row of caption height and makes the
    /// geometry constant, the transition a pure cross-fade, and the predicate's
    /// measurements true at every scroll position rather than only at the one where
    /// they were taken.
    @ViewBuilder
    private var moreBelowCue: some View {
        Image(systemName: "chevron.down")
            .font(.caption2)
            .foregroundStyle(Palette.secondaryText)
            .padding(.bottom, Metrics.space1)
            .opacity(hasContentBelowFold ? 1 : 0)
            .accessibilityHidden(true)
    }

    /// **The counted breath pacer** (HL-017): "in 2 3 4 · out 2 3 4 5 6" under the
    /// live numeral, at the same 4 s / 6 s cadence the glow breathes (decision 0036
    /// slice 4) — the one feature the category's beloved competitor is credited
    /// for, delivered as a line of small type instead of a mode. Opt-in, off by
    /// default: a pacer nobody asked for is chatter.
    ///
    /// Derived from the same wall clock the screen already renders against —
    /// elapsed mod 10 — rather than sharing the glow's task-driven toggle, which
    /// accumulates sleep lag over minutes. The counts are the *readable* half of
    /// the cadence, and under Reduce Motion they are the whole of it: the glow
    /// holds still and the numbers keep counting — a numeric fallback is stillness
    /// with information, not motion by another name.
    @AppStorage("breathPacerWhileTiming") private var breathPacerWhileTiming = false

    private func breathPacerLine(now: Date) -> String? {
        guard breathPacerWhileTiming, let since = model.runningSince else { return nil }
        let elapsed = now.timeIntervalSince(since)
        guard elapsed >= 0 else { return nil }
        // The counted digit run itself carries no grammar to translate (it is a
        // visual rhythm cue, hidden from VoiceOver entirely — see the caller) —
        // only the word ahead of it does, and that word used to be glued on with
        // a bare Swift `+ " " +` rather than positioned by the catalog. Two
        // complete format strings, one per word, replace it: a translator can
        // move the digit run to either side of the word (or drop the space) for
        // their own language, which concatenation could not offer.
        let position = elapsed.truncatingRemainder(dividingBy: 10)
        let counted = { (upTo: Int) in (1...upTo).map(String.init).joined(separator: " ") }
        if position < 4 {
            return String(localized: "in \(counted(Int(position) + 1))", comment: "breath-pacer inhale count, e.g. \"in 2 3 4\" — visual only, hidden from VoiceOver")
        }
        return String(localized: "out \(counted(Int(position - 4) + 1))", comment: "breath-pacer exhale count, e.g. \"out 2 3 4 5 6\" — visual only, hidden from VoiceOver")
    }

    /// **The optional heartbeat** (HL-012): a soft tick every fifteen seconds while
    /// a contraction is timed, so the phone can lie face-down or sit in a pocket and
    /// still be trusted. Off by default — a haptic nobody asked for is noise — and
    /// silent under Low Power Mode, where the OS is already shedding niceties and a
    /// twelve-hour night needs the battery more than the reassurance.
    @AppStorage("heartbeatWhileTiming") private var heartbeatWhileTiming = false

    /// Which fifteen-second beat the running contraction is in, or nil when the
    /// heartbeat has nothing to say. `sensoryFeedback` fires on the *change*, so
    /// deriving the beat index from the same clock the screen already renders
    /// against costs nothing and re-arms no timer (the HL-011 lesson: everything
    /// on this screen rides the one `TimelineView`).
    private func heartbeatBeat(now: Date) -> Int? {
        guard heartbeatWhileTiming, !ProcessInfo.processInfo.isLowPowerModeEnabled,
              let since = model.runningSince else { return nil }
        let beat = Int(now.timeIntervalSince(since) / 15)
        return beat > 0 ? beat : nil
    }

    var body: some View {
        NavigationStack(path: $path) {
            // **A stand, or a hand** (HL-058, decision 0064). The window's size class
            // and aspect pick the regime; in the regular ones the instrument is joined
            // by the ledger — History's rows for this stretch, live. The GeometryReader
            // sits at the root so a Stage Manager resize re-picks continuously, and
            // every piece of state a switch could rebuild lives on this screen, above
            // it.
            //
            // HL-061 (decision 0066) adds the fold: where an iPhone Duo's hinge crosses
            // this reader, and whether it stands half open. Both are nil and false on
            // every device without one.
            GeometryReader { proxy in
                let fold = proxy.activeFold
                let regime = LayoutRegime(sizeClass: horizontalSizeClass, size: proxy.size,
                                          fold: fold, isHalfOpen: isHalfOpen)
                // One-second cadence: the elapsed figure and the pattern both move with
                // the clock, not with taps. Paused automatically off-screen. Under
                // `-uitesting` the schedule stands still (DesignKit's RuntimeFlags) so
                // screenshots and XCUITests see a settled tree instead of a clock that
                // never stops ticking mid-assertion.
                TimelineView(.secondly) { timeline in
                    let pattern = model.pattern(now: timeline.date)
                    Group {
                        if regime == .tabletop, let fold {
                            // The upright half reads; the half on the nightstand is the
                            // button. Nothing is drawn across the crease itself.
                            VStack(spacing: 0) {
                                instrument(pattern, now: timeline.date, regime: regime)
                                    .frame(height: max(0, fold.minY))
                                Color.clear.frame(height: fold.height)
                                pinnedBar(now: timeline.date, fillsHeight: true)
                                    .frame(maxHeight: .infinity)
                            }
                            // A container, so the identifier names the layout without
                            // overwriting the slab's own beneath it.
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("tabletop")
                        } else {
                            HStack(spacing: 0) {
                                instrument(pattern, now: timeline.date, regime: regime)
                                    .frame(maxWidth: .infinity)
                                if regime.showsLedger {
                                    // The edge `Palette.raised` requires to carry its step.
                                    Rectangle()
                                        .fill(Palette.hairline)
                                        .frame(width: Metrics.hairline)
                                    LedgerPane(episode: pattern.episode, corrections: $corrections)
                                        .frame(width: regime.ledgerWidth(for: proxy.size, fold: fold))
                                        .accessibilityIdentifier("ledger")
                                }
                            }
                        }
                    }
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: regime)
                    // HL-062: clear of the inner display's under-display camera.
                    .padding(proxy.occlusionInsets)
                }
            }
            .background(Palette.screen)
            .readsHalfOpen($isHalfOpen)
            // **Magic Tap** (SP-210): two-finger double-tap anywhere starts or ends
            // the contraction — the system Stopwatch convention, and the fix for the
            // one control that matters sitting last in swipe order (bottom
            // `safeAreaInset`, after the header, chip, readout, tape, timeline and
            // status — eight-plus swipes mid-contraction). Attached at the screen
            // level so it works wherever her focus happens to be. The announcement
            // speaks the *result* — what was recorded, not what was pressed — because
            // her finger never touched the slab and its own label never spoke.
            .accessibilityAction(.magicTap) {
                let now = Date()
                let endingSince = model.runningSince
                model.tap(at: now)
                noteSlipIfJustRecorded()
                if let since = endingSince {
                    let length = LaborFormat.spoken(.seconds(max(0, now.timeIntervalSince(since))))
                    AccessibilityNotification.Announcement(
                        String(localized: "Recorded \(length)", comment: "VoiceOver announcement after a Magic Tap ends a contraction, naming the recorded duration")
                    ).post()
                } else {
                    AccessibilityNotification.Announcement(
                        String(localized: "Timing", comment: "VoiceOver announcement after a Magic Tap starts a contraction")
                    ).post()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink("History", value: Route.history)
                        // HL-048: test scaffolding, not app design. The store-shot
                        // sweep has to reach this screen in nine languages, and its
                        // label is 履歴 in one of them — a coordinate or a label match
                        // would be an English assumption baked into a tool whose whole
                        // job is proving the app is not English. An identifier is
                        // invisible to VoiceOver, which keeps reading the label above.
                        .accessibilityIdentifier("nav.history")
                }
                // Guidance stays pinned. The header chip scrolls away with the
                // content, and the screen that holds "call now regardless" —
                // bleeding, water breaking, reduced movement — must be reachable
                // from any scroll position, not just the top of a long labor.
                //
                // **HL-007's second pseudolocale fix.** This was
                // `NavigationLink("Guidance") { … }` — a text label, same as
                // `?`'s icon-only neighbor was not. The pseudolocale leg's
                // doubled-length run showed why that is fragile independent of
                // any one language: two trailing items sharing the bar with a
                // leading "History" pill only fit because "Guidance" happened to
                // measure short in English. iOS itself agreed the row was full —
                // it folded `?` in with it into a single overflow "…" the moment
                // the label grew, silently breaking the "Guidance stays pinned"
                // contract this very comment states. Text width is the variable
                // no source change can pin down (a translator's word for
                // "Guidance" is theirs to choose, and this pseudolocale run
                // doubles it before any translation exists to judge). An SF
                // Symbol has no such variable — its width is the same glyph in
                // every locale — so trading the text label for one, the same
                // icon-plus-`accessibilityLabel` shape `?` and History's own
                // overflow menu already use, makes the trailing group's width
                // constant regardless of language or pseudolocale length. Two
                // fixed-width icons can never grow past the bar and can never be
                // swept into a "…" of their own.
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: Route.guidance) {
                        Image(systemName: "list.bullet.clipboard")
                    }
                    .accessibilityLabel(String(localized: "Guidance", comment: "VoiceOver label for the toolbar's pinned button that opens the Guidance screen (the guideline, provider number, and call-now-regardless instructions)"))
                    // HL-048 — see `nav.history` above for why this is an identifier
                    // and not a label match.
                    .accessibilityIdentifier("nav.guidance")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingHowItWorks = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .accessibilityLabel(String(localized: "How it works", comment: "VoiceOver label for the toolbar's question-mark button that reopens the How It Works sheet"))
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .history: HistoryScreen()
                case .guidance: GuidanceScreen()
                }
            }
            // HL-058b: each keyboard command does exactly what its tap does — and only
            // where the tap could land. The commands are disabled by the same facts
            // (`KeyboardIntents`); the guards here are the second lock on a record.
            .onChange(of: keyboard.tapSlab) {
                guard keyboard.timerIsFrontmost else { return }
                model.tap(at: Date())
                noteSlipIfJustRecorded()
            }
            .onChange(of: keyboard.undo) {
                guard model.undoAction != nil else { return }
                model.undo()
                corrections += 1
            }
            .onChange(of: keyboard.openHistory) { if keyboard.canNavigate { path = [.history] } }
            .onChange(of: keyboard.openGuidance) { if keyboard.canNavigate { path = [.guidance] } }
            .onChange(of: path.isEmpty, initial: true) { _, empty in keyboard.pushedScreen = !empty }
            .onChange(of: isShowingHowItWorks) { _, shown in keyboard.sheet(shown) }
            .onChange(of: isShowingClosureKeepsake) { _, shown in keyboard.sheet(shown) }
            // Once on first launch, then only ever by request. `onAppear` rather
            // than eagerly in `init` so the sheet presents over a settled screen.
            // The QA pass launches fresh installs against every screen in turn —
            // the sheet must not sit on top of every one of those screenshots.
            .onAppear {
                if !hasSeenHowItWorks && !RuntimeFlags.isUITesting { isShowingHowItWorks = true }
            }
            .sheet(isPresented: $isShowingHowItWorks) {
                hasSeenHowItWorks = true
            } content: {
                HowItWorksScreen()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            // SP-215: the recap's "Clear the instrument" opens the exact same
            // dialog History's own Clear All does (`ClearHistoryConfirmation`) —
            // never a second deletion path.
            .clearHistoryConfirmation(isPresented: $isConfirmingClear, episodeToSave: lastEpisode)
        }
    }

    // MARK: The live hero

    /// The elapsed figure at the identity's full `.dataText(.hero)` size — HL-003
    /// slice 1's other half of "the hero leaves the disc". Ember, not the room's
    /// plain ink: `emberLive` is verified straight against `Palette.screen` (12.70:1
    /// dark, 6.27:1 light — `PaletteContrastTests`), and it is the token the identity
    /// names for exactly this figure ("the live elapsed numeral... brightens from
    /// accent-ember"). `emberLive` may otherwise never stand alone as a colour
    /// distinction (Palette.swift), but it does not here — the figure's mere presence
    /// already says "live", the same second signal the token's own rule asks for.
    ///
    /// Idle, the slot is empty rather than printing "since last" at this scale
    /// (decision 0036 §Rationale): the header already prints `LAST … AGO`, and
    /// `SnapshotFactAssertionTests` anchors on that fact, so a second rendering of
    /// the same figure at a different size would have the screen contradicting
    /// itself. No reserved frame for the empty case either — "no fixed frame heights
    /// on text containers" is the house rule, and an empty install has nothing to
    /// hold a placeholder's height accountable to.
    ///
    /// **It speaks for itself**, rather than being hidden behind the button that
    /// happens to repeat it. An earlier draft marked this `.accessibilityHidden(true)`
    /// on the grounds that the button's own `accessibilityValue`
    /// (`spokenButtonValue(now:)`) already says the figure on demand, so a second
    /// element would be two elements for one fact. That reasoning traded a real
    /// omission for a tidier swipe order: the largest thing on a running screen was
    /// left on it with nothing backing it, which `XCUIAccessibilityAuditTypeElementDetection`
    /// reported against `running/scrolled` at AX5 — exactly the finding the ember
    /// tape's end caps were corrected for in the same slice (`EmberTape`, decision
    /// 0037). Visible words get a real accessible counterpart; that rule does not
    /// have an exception for the words a control elsewhere also mentions.
    ///
    /// Spoken as a duration, never as the printed `0:14` — a numeral slot read glyph
    /// by glyph is not a measurement — and carrying `.updatesFrequently`, which is the
    /// API's own way of saying "this figure moves". That trait is what answers the
    /// original worry: it tells VoiceOver to re-read the figure when she asks for it
    /// rather than treating each tick as new content to interrupt her with, so the
    /// `TimelineView` still never decides when she is spoken to.
    @ViewBuilder
    private func liveHero(now: Date, regime: LayoutRegime = .compact) -> some View {
        if let since = model.runningSince {
            let elapsed = Duration.seconds(max(0, now.timeIntervalSince(since)))
            Text(LaborFormat.minutesSeconds(elapsed))
                // The stand is read across the room and the tabletop from the bed:
                // the hero further away (HL-058, HL-061).
                .dataText(regime.readsAtDistance ? .distance : .hero)
                .foregroundStyle(Palette.emberLive)
                .contentTransition(.numericText(countsDown: false))
                .animation(reduceMotion ? nil : .linear(duration: 0.2), value: now)
                .accessibilityLabel(LaborFormat.spoken(elapsed))
                .accessibilityAddTraits(.updatesFrequently)
            // The pacer rides directly under the numeral it breathes beside.
            // Hidden from VoiceOver — unlike the numeral above (decision 0038),
            // whose figure is real state worth reaching, this line mutates every
            // second purely as rhythm, and a breath cadence is felt and seen,
            // not usefully spoken digit by digit.
            if let pacer = breathPacerLine(now: now) {
                Text(pacer)
                    .dataText(.label)
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityHidden(true)
            }
        }
    }


    // MARK: The instrument

    /// The iPhone timer, given room. The readout scrolls; the button never does. At
    /// accessibility type sizes the verdict text grows past a screenful, and the §8
    /// rule is that it wraps and scrolls — the one sentence that says "call now" must
    /// never truncate. The button pins to the pane's bottom via the safe area inset,
    /// so the tap target is identical at every type size and in every regime.
    private func instrument(_ pattern: LaborPattern, now: Date, regime: LayoutRegime) -> some View {
                ScrollView {
                    VStack(alignment: .leading, spacing: Metrics.space5) {
                        // The header goes *below* the verdict at accessibility sizes
                        // (decision 0027). It is ~208 pt there — three wrapped lines of
                        // mono caps plus the chip — and capping the button alone still
                        // left the verdict starting below the fold on the smaller
                        // devices. Identity and the chip are the two things on this
                        // screen that can afford to be scrolled to; the sentence that
                        // says calling is reasonable is not. Guidance's own toolbar
                        // item is pinned, so the rule stays one tap away regardless.
                        if !dynamicTypeSize.isAccessibilitySize && regime != .tabletop {
                            header(pattern, now: now)
                        }
                        // Order follows the state (SP-187's screen cards): once the
                        // guideline is met the verdict leads and the timeline recedes;
                        // while the pattern is still building, the timeline is the
                        // content and the partial line trails it.
                        //
                        // At accessibility sizes the sentence leads outright, ahead of
                        // the readout, whatever the state — three columns of 26-pt
                        // numerals scaled to AX5 fill the screen on their own, and the
                        // verdict is the one thing on this surface that must be read
                        // without scrolling.
                        //
                        // The order keys on the **latched** verdict (decision 0025):
                        // reordering is a several-hundred-point block animating in
                        // above the reader's scroll position, and it may only happen
                        // as often as the verdict genuinely changes — not every time
                        // a windowed mean wobbles across its threshold and back.
                        //
                        // HL-003 slice 1's live numeral takes its place *inside* these
                        // branches rather than above them. At ordinary sizes it leads —
                        // it is the one thing on this screen that changes every second,
                        // and the identity puts it where the eye lands first. At
                        // accessibility sizes it yields to the verdict like everything
                        // else does: an 84 pt figure scaled off `largeTitle` fills the
                        // top third at AX5, and a screen that opens on the elapsed count
                        // while the sentence about calling runs under the bar is the
                        // exact failure 0027 was written against. She is holding the
                        // phone that is counting; the count is not the thing she needs
                        // first.
                        if dynamicTypeSize.isAccessibilitySize {
                            guidance(pattern, now: now)
                            runningLongNotice(now: now)
                            liveHero(now: now, regime: regime)
                            header(pattern, now: now)
                            readout(pattern, now: now)
                            timelineSection(pattern, now: now)
                        } else if regime == .tabletop {
                            // HL-061: the upright half of a half-open Duo is roughly
                            // two-fifths of a screen, read from the bed. What is read
                            // from there leads — the count, then the verdict when there
                            // is one — and the header that identifies the screen goes
                            // last, where it does at accessibility sizes (0027).
                            liveHero(now: now, regime: regime)
                            if pattern.presentedMet { guidance(pattern, now: now) }
                            readout(pattern, now: now)
                            timelineSection(pattern, now: now)
                            if !pattern.presentedMet { guidance(pattern, now: now) }
                            header(pattern, now: now)
                        } else if pattern.presentedMet {
                            liveHero(now: now, regime: regime)
                            readout(pattern, now: now)
                            guidance(pattern, now: now)
                            timelineSection(pattern, now: now)
                        } else {
                            liveHero(now: now, regime: regime)
                            readout(pattern, now: now)
                            timelineSection(pattern, now: now)
                            guidance(pattern, now: now)
                        }
                    }
                    .padding(.horizontal, Metrics.screenMargin)
                    .padding(.bottom, Metrics.space4)
                    // The verdict's arrival and each new node are events worth a
                    // beat of motion; the keys are the facts that change, so ticks
                    // alone animate nothing.
                    .animation(
                        reduceMotion ? nil : .spring(duration: 0.45),
                        value: pattern.presentedMet
                    )
                    .animation(
                        reduceMotion ? nil : .spring(duration: 0.35),
                        value: pattern.episode.count
                    )
                }
                // **HL-007's first pseudolocale fix, part one.** iOS 26 fades
                // scrolled content automatically as it nears a `safeAreaInset`
                // edge — `.automatic`, the default, is exactly the soft Liquid
                // Glass blend the pseudolocale run caught bleeding the
                // verdict's last wrapped line through the pinned bar (see the
                // longer account on the bar's own background below, part two,
                // for how the finding was actually diagnosed: the two
                // mechanisms compound, and both had to be addressed). `.hard`
                // is Apple's own named opt-out — the scrolled content simply
                // stops at the edge, cleanly, which is what "wraps and
                // scrolls, never through it" already asked for.
                .hardBottomScrollEdge()
                // Remaining scrollable distance, sampled as the geometry changes.
                //
                // Every term here was measured on this screen rather than reasoned
                // out, because two of `ScrollGeometry`'s members do not mean what
                // their names suggest and the resulting error is a *constant* — the
                // kind that still renders something plausible and is only caught by
                // scrolling to the very bottom and finding the cue still lit.
                //
                // `containerSize` (533 pt here) is the region *between* the insets,
                // not the full container (873); `contentOffset.y` starts at
                // −contentInsets.top (−116) rather than 0. So `contentOffset.y +
                // contentInsets.top` is how far into the content the visible window
                // begins — 0 at rest at the top, which is the number this needs —
                // and adding `containerSize.height` gives its bottom edge in the
                // content's own coordinates. Measured: 533 at the top of an 806 pt
                // content (273 to go) and 805 at the true bottom (1 pt of rounding).
                //
                // Which is what the threshold is for: a hair over zero rather than
                // exactly zero, so that 1 pt of residue cannot leave the chevron
                // showing over a screen with nothing left to show.
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    let visibleBottom = geometry.contentOffset.y
                        + geometry.contentInsets.top
                        + geometry.containerSize.height
                    return geometry.contentSize.height - visibleBottom > 8
                } action: { _, hasMore in
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                        hasContentBelowFold = hasMore
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    // On a tabletop the bar is the whole lower half instead, laid out
                    // by the caller (HL-061); the cue about *this* scroll stays here,
                    // just above the crease, where the content it speaks for ends.
                    if regime == .tabletop {
                        moreBelowCue.frame(maxWidth: .infinity).background(Palette.screen)
                    } else {
                        pinnedBar(now: now, fillsHeight: false)
                    }
                }
    }

    /// The bar pinned under the instrument: the slab, the slip strip above it, and the
    /// cue that more of the readout is below. `fillsHeight` is the tabletop's: the
    /// half lying on the nightstand is all button (HL-061).
    private func pinnedBar(now: Date, fillsHeight: Bool) -> some View {
        // **HL-007's first pseudolocale fix, part two.** This was
        // `.background(.bar)` — a translucent system Material — on
        // the strength of the comment above it ("opaque... never
        // through it"). Two mechanisms compounded to break that
        // promise, and both had to go: iOS 26's automatic scroll-
        // edge fade (part one, above) let the verdict's last wrapped
        // line — landing, honestly, right at the ScrollView's resting
        // fold, exactly where any tall content's fold falls, at
        // doubled length + XL — bleed through *before* it ever
        // reached the bar; `.bar`'s own frosted-glass translucency
        // would have let it bleed through a second time even with
        // the edge effect off. A reader saw a sentence fade into the
        // slab rather than stop at it, which read as the figure
        // clipping even though nothing was lost — the rest was one
        // scroll away, unchanged, the whole time. `Palette.raised` is
        // a flat, fully opaque fill: the same content, at the same
        // scroll position, now simply stops at the bar's edge, which
        // is what "never through it" already promised. `raised`'s own
        // doc comment requires a hairline or shadow to carry its
        // boundary at its 1.09:1/1.06:1 step — the top hairline below
        // is that, and it doubles as the visual seam between scrolled
        // content and the pinned control.
        //
        // The slip strip lives *inside* the inset, above the slab. The
        // inset is anchored to the bottom edge, so the strip grows the bar
        // upward and the slab stays exactly where her thumb left it — a
        // correction offered must never move the control it interrupts.
        VStack(spacing: Metrics.space3) {
            if !fillsHeight { moreBelowCue }
            slipStrip
            slab(now: now, fillsHeight: fillsHeight)
        }
        .padding(.horizontal, Metrics.screenMargin)
        .padding(.vertical, Metrics.space3)
        .background(Palette.raised)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Palette.hairline)
                .frame(height: Metrics.hairline)
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.3), value: slip)
        .sensoryFeedback(.levelChange, trigger: corrections)
        // The heartbeat rides the bar because the bar already owns
        // this screen's other ambient feedback; `.impact(weight:
        // .light)` is quieter than the start/stop textures on
        // purpose — a pulse felt through a pocket, never mistaken
        // for a tap landing.
        .sensoryFeedback(trigger: heartbeatBeat(now: now)) { _, beat in
            beat == nil ? nil : .impact(weight: .light)
        }
    }

    // MARK: Header

    @ViewBuilder
    private func header(_ pattern: LaborPattern, now: Date) -> some View {
        // Side by side while it fits; stacked at accessibility sizes, where the two
        // labels would otherwise overlap each other under the toolbar.
        ViewThatFits(in: .horizontal) {
            HStack {
                headerLabels(pattern, now: now, alignment: .trailing)
            }
            VStack(alignment: .leading, spacing: Metrics.space2) {
                headerLabels(pattern, now: now, alignment: .leading)
            }
        }
        .padding(.top, Metrics.space4)
    }

    @ViewBuilder
    private func headerLabels(
        _ pattern: LaborPattern,
        now: Date,
        alignment: HorizontalAlignment
    ) -> some View {
        // "SINCE 7:42 PM · LAST 45 M AGO" — when this stretch began, and how old the
        // figures beside it are.
        Text(headerText(pattern, now: now))
            .sectionLabelText()
            .accessibilityLabel(spokenHeader(pattern, now: now))
        if alignment == .trailing { Spacer(minLength: Metrics.space3) }
        // The guideline chip: which rule this screen is judging against, one tap
        // from changing it. Surfaced here so the rule is set before the night —
        // the alternative (a quiz before the timer) is the competitor's move.
        NavigationLink(value: Route.guidance) {
            // HL-009: the chevron used to be baked into the localized string itself
            // ("\(model.rule.label) ›") — a literal `›` glyph, which is exactly the
            // kind of directional literal decision 0045 asks this item to sweep for.
            // Unicode does not mirror an arbitrary character for layout direction,
            // so under forced RTL the disclosure arrow kept pointing right while
            // the chip itself moved to the opposite side of the header — a chip
            // that visually pointed the wrong way. `chevron.forward` is the SF
            // Symbol pair's direction-aware member (paired with `chevron.backward`,
            // as opposed to the literal, never-mirroring `chevron.right`/`.left`):
            // it renders pointing toward reading-forward, flipping automatically
            // with `\.layoutDirection` the same way `HStack` ordering does. Split
            // out of the string entirely, so a translator's copy is just the rule
            // label, with no punctuation mark to puzzle over or accidentally
            // localize a direction into.
            HStack(spacing: Metrics.space1) {
                Text(model.rule.label)
                Image(systemName: "chevron.forward")
                    // Decorative: the label already reads as a rule shorthand, and
                    // `NavigationLink` supplies its own "opens a new screen"
                    // accessibility semantics — the glyph would otherwise be
                    // spoken as a stray punctuation mark, the way the old baked-in
                    // "›" was.
                    .accessibilityHidden(true)
                    .imageScale(.small)
            }
            .dataText(.label)
            .foregroundStyle(Palette.primaryText)
            .padding(.horizontal, Metrics.space3)
            .padding(.vertical, Metrics.space2)
            // The capsule is drawn on the padded box, so the chip stays
            // chip-sized — then the hit region is grown around it. 28 pt was
            // 16 short of HIG's minimum, and growing the *drawn* capsule to 44
            // would make a section-label chip look like a primary button.
            // `contentShape` takes the shape of the frame it is applied to, so
            // it has to come after the frame rather than before it; that
            // ordering was the whole of the bug. Only binds up to AX2 — past
            // that the chip's own height already clears 44.
            .overlay(Capsule().strokeBorder(Palette.hairline, lineWidth: 1))
            .frame(minHeight: Metrics.minimumTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Guideline \(model.rule.label)", comment: "VoiceOver label for the header's guideline chip, naming the selected rule"))
        .accessibilityHint(String(localized: "Opens guidance", comment: "VoiceOver hint for the header's guideline chip"))
    }

    private func headerText(_ pattern: LaborPattern, now: Date) -> String {
        var parts = [String(localized: "CONTRACTIONS", comment: "timer header first clause, the section name. Rendered in caps by the type role, so translate as a word rather than in capitals")]
        if let start = pattern.episodeStart {
            // An episode legally spans days (the 2 h gap rule), and "SINCE 5:13 PM"
            // alone has no answer for "which evening?" once it's read again after
            // midnight (decision 0022 §3, SP-214). `LaborFormat.since` adds the day
            // only when `start` isn't today, so the common case is unchanged.
            parts.append(LaborFormat.since(start, now: now))
        }
        if let ago = lastEndedAgo(pattern, now: now) {
            // `gap`, not `hoursMinutes`: this is how long *ago*, not how long *for*.
            // Its sub-minute branch never fires here — `lastEndedAgo` withholds below
            // a minute — so what it buys the header is "LAST 2 H AGO" over
            // "LAST 2 H 0 M AGO".
            parts.append(String(localized: "LAST \(LaborFormat.gap(ago).uppercased()) AGO", comment: "timer header clause: how long ago the last contraction ended. Rendered in caps by the type role. The argument is an already-formatted duration"))
        }
        return parts.joined(separator: " · ")
    }

    /// The spoken form of the mono-caps header `headerText` builds above.
    ///
    /// **HL-007's line, drawn here.** Four shapes, not three fragments a Swift
    /// `+=` glued in a fixed order: whether the SINCE clause and the LAST-ended
    /// clause are each present is still engine truth (`pattern.episodeStart` and
    /// `lastEndedAgo(pattern:now:)` decide it, exactly as before), but every
    /// reachable combination is now its own complete catalog sentence, so a
    /// translator can freely reorder "since when" against "how long ago the last
    /// one ended" — or drop the leading comma English happens to want — rather
    /// than inheriting Swift's append order and punctuation unconditionally.
    private func spokenHeader(_ pattern: LaborPattern, now: Date) -> String {
        let since = pattern.episodeStart.map { LaborFormat.spokenSince($0, now: now) }
        let ago = lastEndedAgo(pattern, now: now).map { LaborFormat.spoken($0) }
        switch (since, ago) {
        case let (.some(since), .some(ago)):
            return String(localized: "Contractions, \(since), last one ended \(ago) ago", comment: "VoiceOver: spoken header, prose form of the mono-caps CONTRACTIONS label, naming both when the episode began and how long ago the last contraction ended")
        case let (.some(since), .none):
            return String(localized: "Contractions, \(since)", comment: "VoiceOver: spoken header, prose form of the mono-caps CONTRACTIONS label, naming when the episode began (no finished contraction to date yet)")
        case let (.none, .some(ago)):
            return String(localized: "Contractions, last one ended \(ago) ago", comment: "VoiceOver: spoken header, prose form of the mono-caps CONTRACTIONS label, naming how long ago the last contraction ended (no episode start to name — practically unreachable, a finished contraction implies a start)")
        case (.none, .none):
            return String(localized: "Contractions", comment: "VoiceOver: spoken header, prose form of the mono-caps CONTRACTIONS label, before any contraction has been recorded")
        }
    }

    /// How long ago the newest *finished* contraction ended (decision 0022 §3).
    ///
    /// A raw fact about the record, so no evidence floor applies to it — that is the
    /// point. Without it, averages, LAST and the banner all render forty-five-minute-
    /// old measurements in the present tense with only SINCE (thirteen hours ago) to
    /// date them, and the reader has no way to know the screen has gone quiet.
    ///
    /// Withheld while a contraction is running — the live count on the button already
    /// dates the screen — and below a minute, where "LAST 0 M AGO" would print a zero
    /// in a data slot and nothing has gone stale anyway.
    private func lastEndedAgo(_ pattern: LaborPattern, now: Date) -> Duration? {
        guard pattern.running == nil,
              let ended = pattern.episode.compactMap(\.endedAt).max()
        else { return nil }
        let gap = Duration.seconds(max(0, now.timeIntervalSince(ended)))
        return gap >= .seconds(60) ? gap : nil
    }

    // MARK: Readout

    /// Three measured columns, mirroring Today's adherence cluster. Absent until
    /// there is enough to measure — the same rule as everywhere else in the
    /// ecosystem, applied where a fabricated average could send someone to the
    /// hospital or keep them home.
    @ViewBuilder
    private func readout(_ pattern: LaborPattern, now: Date) -> some View {
        // The instrument at rest (SP-189, and decision 0037 §3 for the tape): an
        // empty install shows the same columns and tape it will fill — em dashes
        // where measurements will be, never a zero, and the ember tape's own grid
        // and baseline with no bars on them yet, rather than a decorative stand-in
        // beside it. The screen's promise is its own anatomy, not a paragraph about
        // it.
        if pattern.episode.isEmpty {
            // SP-215: which acknowledgment renders is one fork, decided once — the
            // closure recap when the newest record reads as *concluded*
            // (`EpisodeClosure`, days old), the short "last contraction ended …
            // ago" line for anything younger than that, and the truly-empty
            // teaching copy only when the store has never held a record at all.
            // `emptyStateCopy` keeps owning the latter two exactly as it always
            // has — this only ever decides whether it is asked for the third at
            // all, so the recap can never quietly displace the first-launch
            // teaching copy the way an unconditional insertion above it would.
            let concluded = EpisodeClosure.isConcluded(
                lastEndedAt: model.lastEndedAt, isRunning: model.isRunning, now: now
            )
            VStack(alignment: .leading, spacing: Metrics.space5) {
                if concluded {
                    closureRecap(episode: lastEpisode)
                }
                VStack(alignment: .leading, spacing: Metrics.space3) {
                    columns(nil)
                    emberTape(for: nil, now: now)
                }
                if !concluded {
                    emptyStateCopy(now: now)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: Metrics.space3) {
                columns(pattern)
                emberTape(for: pattern, now: now)
            }
        }
    }

    /// The most recent episode, chronological (oldest first) — what the closure
    /// recap reads its figures from and what "Keep a copy" exports. One
    /// definition (`PatternAnalysis.episodes(_:).last`, the exact call
    /// `ClearHistoryConfirmation`'s own newest-episode reasoning uses) so the
    /// stretch the recap describes and the stretch the keepsake exports can never
    /// be two different episodes (F-0012). Independent of `pattern.episode`,
    /// which is empty by the time this is ever read — a stale episode is exactly
    /// what makes `rawPattern` return `.empty` in the first place.
    private var lastEpisode: [Contraction] {
        PatternAnalysis.episodes(model.contractions).last ?? []
    }

    /// **SP-215: the quiet off-ramp.** Decision 0029 §1's hard wall governs every
    /// word here — the app registers that a stretch of contractions ended; it
    /// never narrates what happened next. No card, no wash: the sage rise
    /// (`Palette.goTimeFill`) belongs to the verdict banner alone, and dressing
    /// this acknowledgment in the same light would borrow a moment it did not
    /// earn. `secondaryText` throughout, the same register the header's own dated
    /// figures already use — a steady midwife tidying the room, not a second
    /// verdict.
    ///
    /// Two actions, both quiet (`capsuleNeutral` — "a low-emphasis chip with no
    /// semantic weight"): neither is this screen's primary call to action, and
    /// "Clear the instrument" routes to the exact confirmation History's own
    /// Clear All opens (`ClearHistoryConfirmation`) rather than a second deletion
    /// path the item explicitly rules out.
    @ViewBuilder
    private func closureRecap(episode: [Contraction]) -> some View {
        if let summary = PatternAnalysis.summary(of: episode) {
            VStack(alignment: .leading, spacing: Metrics.space3) {
                Text(LaborFormat.recapLine(summary, startedAt: episode.first?.startedAt))
                    .font(.prose)
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityLabel(
                        LaborFormat.spokenRecapLine(summary, startedAt: episode.first?.startedAt)
                    )

                // Side by side while it fits; stacked at accessibility sizes — the
                // same `ViewThatFits` pattern the header and the verdict's leg
                // rows already take, so two capsules never squeeze into a column
                // each that clips.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Metrics.space3) {
                        keepACopyButton
                        clearInstrumentButton
                    }
                    VStack(alignment: .leading, spacing: Metrics.space3) {
                        keepACopyButton
                        clearInstrumentButton
                    }
                }
            }
        }
    }

    private var keepACopyButton: some View {
        Button("Keep a copy") {
            isShowingClosureKeepsake = true
        }
        .buttonStyle(.capsuleNeutral)
        .accessibilityHint(String(localized: "Shows the last stretch, to read or share", comment: "VoiceOver hint for the Keep a copy button in the closure recap"))
        .sheet(isPresented: $isShowingClosureKeepsake) {
            if let summary = PatternAnalysis.callSummary(of: lastEpisode) {
                ForTheCallScreen(
                    episode: lastEpisode,
                    summary: summary,
                    // Opened from "Keep a copy" on a stretch that has ended — the
                    // card lands on the name the button promised (F-0047).
                    title: LocalizedStringResource("Keep a copy", comment: "navigation title of the summary card when opened from the closure recap, where the stretch has ended and the offer is a keepsake rather than a script")
                )
            }
        }
    }

    private var clearInstrumentButton: some View {
        Button("Clear the instrument") {
            isConfirmingClear = true
        }
        .buttonStyle(.capsuleNeutral)
        .accessibilityHint(String(localized: "Opens the clear-history confirmation", comment: "VoiceOver hint for the Clear the instrument button in the closure recap"))
    }

    /// **Shape, not a derived fill** (decision 0037, superseding 0022 §6 and 0026
    /// §2's tape semantics). `TickTapeGauge` rendered one number — sustained-evidence
    /// progress toward the hour — as a percentage; the ember tape draws the raw
    /// contractions that number was derived from, over the same trailing
    /// `rule.sustainedWindow`, right edge pinned to `now`. Continuity becomes
    /// something a reader can check against the picture (bars all the way back to
    /// the left edge, or a growing gap at the leading edge) instead of a figure they
    /// have to trust — the whole of decision 0037's rationale.
    ///
    /// `nil` draws the resting instrument — grid and baseline, no bars — the same
    /// anatomy an empty install and a fully-aged-out pattern both show. This is what
    /// `GhostTimeline`'s silhouette retired into: one real component rather than a
    /// decorative stand-in beside it.
    private func emberTape(for pattern: LaborPattern?, now: Date) -> some View {
        let window = model.rule.sustainedWindow
        let geometry = PatternAnalysis.tape(
            for: pattern?.episode ?? [],
            window: window,
            now: now
        )
        // The count the tape speaks, always `inWindowCount` — the same "started
        // inside the trailing hour" definition the PATTERN column's own detail line
        // already reads ("N contractions in this stretch"), rather than a second
        // count taken from however many bars happen to be drawn (which can run one
        // higher when a bar straddles the window's left edge). One definition of
        // "how many in the last hour," the same rule `interval(from:to:)` exists to
        // keep everywhere else in this engine.
        let count = pattern?.inWindowCount ?? 0

        return EmberTape(
            bars: geometry.bars.map {
                EmberTape.Bar(
                    start: $0.start,
                    width: $0.width,
                    isLive: $0.isLive,
                    isSuspect: $0.suspicion != nil
                )
            },
            // The grid is the rule's own interval, not a wall-clock number (decision
            // 0037 §2) — 5-1-1 draws a tick every 5 of the tape's 60 minutes, and so
            // on, taken from the rule so a 4-1-1 or 3-1-1 reader never sees someone
            // else's cadence on their own tape.
            tickCellFraction: model.rule.intervalThreshold.timeIntervalValue
                / window.timeIntervalValue,
            leadingCaption: String(localized: "1 H AGO", comment: "the ember tape left end cap, the oldest edge of the one-hour window. Rendered in caps by the type role"),
            trailingCaption: String(localized: "NOW", comment: "the ember tape right end cap, the present moment. Rendered in caps by the type role"),
            leadingCaptionSpoken: String(localized: "one hour ago", comment: "VoiceOver: spoken form of the ember tape's left end cap, which prints as mono-caps \"1 H AGO\""),
            trailingCaptionSpoken: String(localized: "now", comment: "VoiceOver: spoken form of the ember tape's right end cap, which prints as mono-caps \"NOW\""),
            accessibilityLabel: Self.tapeAccessibilityLabel,
            // A raw count, never a percentage (decision 0037 §7) — a raw record needs
            // no evidence floor, so this is spoken even at zero, unlike the columns
            // above it.
            accessibilityValue: "\(count)"
        )
    }

    /// The prose beneath the resting instrument.
    ///
    /// Two states, not one (decision 0022 §2). A stale pattern over a non-empty store
    /// used to render the first-launch introduction — to someone twenty-nine hours
    /// into latent labor with seventy contractions in History. The empty state has to
    /// remember that it has been used before.
    @ViewBuilder
    private func emptyStateCopy(now: Date) -> some View {
        VStack(alignment: .leading, spacing: Metrics.space2) {
            if let ended = model.lastEndedAt {
                let gap = Duration.seconds(max(0, now.timeIntervalSince(ended)))
                Text("Last contraction ended \(LaborFormat.gap(gap)) ago.", comment: "empty-state headline once at least one contraction has been recorded, naming how long ago the last one ended")
                    .font(.claim)
                    .foregroundStyle(Palette.primaryText)
                    .accessibilityLabel(
                        String(localized: "Last contraction ended \(LaborFormat.spokenGap(gap)) ago", comment: "VoiceOver: spoken form of the empty-state headline naming how long ago the last contraction ended")
                    )
                Text("History has every contraction. The next tap starts a new stretch.", comment: "empty-state caption once at least one contraction has been recorded")
                    .font(.prose)
                    .foregroundStyle(Palette.secondaryText)
            } else {
                Text("No contractions yet.", comment: "empty-state headline on a fresh install, before any contraction has been recorded")
                    .font(.claim)
                    .foregroundStyle(Palette.primaryText)
                Text("Tap the button when one starts — everything above builds from that one tap. The chip up top holds the guideline your provider gave you.", comment: "empty-state caption on a fresh install, before any contraction has been recorded")
                    .font(.prose)
                    .foregroundStyle(Palette.secondaryText)
            }
        }
    }

    /// The three measured columns, side by side while they fit and stacked when they
    /// do not — the header's own `ViewThatFits` pattern, applied where it was
    /// missing. Three across at AX5 gave each column about a third of the screen, and
    /// 26-pt numerals scaled to that width wrapped mid-figure ("2:5 / 8") while the
    /// labels clipped mid-glyph ("INTER / VAL"). Reflow, never truncation (§8).
    ///
    /// `nil` renders the instrument at rest: the same anatomy an empty install shows,
    /// em dashes where measurements will be.
    @ViewBuilder
    private func columns(_ pattern: LaborPattern?) -> some View {
        let interval = intervalColumn(pattern)
        let duration = durationColumn(pattern)
        let length = patternColumn(pattern)

        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 0) {
                column(interval).frame(maxWidth: .infinity, alignment: .leading)
                divider
                column(duration).frame(maxWidth: .infinity, alignment: .leading)
                divider
                column(length).frame(maxWidth: .infinity, alignment: .leading)
            }
            .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: stackedColumnGap) {
                column(interval)
                column(duration)
                column(length)
            }
        }
    }

    /// The ember tape's accessibility label, named once because two call sites
    /// render it (the resting instrument and the live one) and a reader who heard
    /// them disagree would be hearing two instruments. Stable across every pattern
    /// state — decision 0037 §7 replaces `TickTapeGauge`'s spoken percentage
    /// (`"unbroken pattern toward one hour"`, paired with a `%` accessibility value)
    /// with a raw count paired with this label; see
    /// `HushlightUITests/SnapshotFactAssertionTests.swift`'s `ScreenCapture.tapeLabel`,
    /// re-cut in the same commit.
    private static var tapeAccessibilityLabel: String {
        String(localized: "contractions in the last hour", comment: "VoiceOver label for the ember tape, paired with a raw count as its accessibility value")
    }

    /// One column's content, resolved before layout so the horizontal and stacked
    /// arrangements can never say different things.
    private struct ReadoutColumn {
        var label: String
        var value: String?
        var detail: String?
        var spokenValue: String?
        /// The detail line's spoken form. Printed details used to be invisible to
        /// VoiceOver entirely — the column combines its children and speaks only
        /// label and value — which would have made the spread below a decoration
        /// only sighted readers get.
        var spokenDetail: String?
    }

    private func intervalColumn(_ pattern: LaborPattern?) -> ReadoutColumn {
        // The detail slot is the in-window **range**, not the newest gap (decision
        // 0024 §2). A mean is a value that never occurs in a bimodal pattern, and
        // "INTERVAL 10:53" beside "LAST 20:58" read as one row disagreeing with
        // itself about the same measurement (F-0012). The spread is a raw fact and
        // says the thing the mean cannot: whether these gaps resemble each other.
        // Rendered even when both ends coincide — a metronome is information too,
        // and a slot that changes shape to save four characters is a slot that has
        // to be re-learned.
        let range = pattern?.intervalRange
        // `spokenValue` and `spokenDetail` are already two independent, complete
        // catalog sentences, each with its own positional figure argument —
        // `spokenColumnValue(_:)` below is where they are combined, and that
        // join (not either sentence here) is this item's actual concern.
        return ReadoutColumn(
            label: String(localized: "INTERVAL", comment: "the INTERVAL column's label on the timer readout — start-to-start spacing. Rendered in caps by the type role, so translate as a word, not in capitals"),
            value: pattern?.averageInterval.map(LaborFormat.minutesSeconds),
            detail: range.map(LaborFormat.range),
            spokenValue: pattern?.averageInterval.map {
                String(localized: "average \(LaborFormat.spoken($0)) apart", comment: "VoiceOver: spoken value of the INTERVAL column")
            },
            spokenDetail: range.map {
                String(localized: "ranging \(LaborFormat.spoken($0.lowerBound)) to \(LaborFormat.spoken($0.upperBound))", comment: "VoiceOver: spoken detail of the INTERVAL column, the range of intervals in the trailing window")
            }
        )
    }

    private func durationColumn(_ pattern: LaborPattern?) -> ReadoutColumn {
        ReadoutColumn(
            label: String(localized: "DURATION", comment: "the DURATION column's label on the timer readout — how long each contraction lasts. Rendered in caps by the type role, so translate as a word, not in capitals"),
            value: pattern?.averageDuration.map(LaborFormat.minutesSeconds),
            detail: nil,
            spokenValue: pattern?.averageDuration.map {
                String(localized: "average \(LaborFormat.spoken($0)) long", comment: "VoiceOver: spoken value of the DURATION column")
            }
        )
    }

    private func patternColumn(_ pattern: LaborPattern?) -> ReadoutColumn {
        // Withheld below a minute (decision 0022 §7). `hoursMinutes` renders forty
        // seconds as "0 M", which is exactly the zero-as-measurement the em dashes
        // exist to prevent — and it arrived on the *first* contraction, so it was the
        // screen's first impression.
        var length: Duration?
        if let raw = pattern?.patternLength, raw >= .seconds(60) { length = raw }

        return ReadoutColumn(
            label: String(localized: "PATTERN", comment: "the PATTERN column's label on the timer readout — how long this unbroken stretch has run. Rendered in caps by the type role, so translate as a word, not in capitals"),
            value: length.map(LaborFormat.hoursMinutes),
            detail: pattern.map { String(localized: "\($0.episode.count) TOTAL", comment: "PATTERN column detail line: how many contractions this stretch holds. Rendered in caps by the type role. The argument is the count") },
            spokenValue: length.map {
                String(localized: "going for \(LaborFormat.spoken($0))", comment: "VoiceOver: spoken value of the PATTERN column")
            },
            spokenDetail: pattern.map {
                // A real `Int`, interpolated directly — this detail renders
                // whenever an episode exists at all (not gated by any multi-
                // contraction floor, so a lone logged contraction does read this,
                // "1 contraction in this stretch") — so the count keys into the
                // catalog as `%lld` and resolves through `variations.plural`.
                String(localized: "\($0.episode.count) contraction in this stretch", comment: "VoiceOver: spoken detail of the PATTERN column, a raw count of contractions in the current episode — catalog plural entry")
            }
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(width: Metrics.hairline)
            .frame(maxHeight: .infinity)
            .padding(.horizontal, Metrics.space3)
            .accessibilityHidden(true)
    }

    /// A column prints its measurement or, below the evidence floor, an em dash —
    /// never a zero, which would read as a measured value.
    private func column(_ item: ReadoutColumn) -> some View {
        VStack(alignment: .leading, spacing: Metrics.space2) {
            Text(item.value ?? "—")
                .dataText(.stat)
                // The figure takes its natural width rather than the column's, so
                // "2:58" can never break into "2:5 / 8". Wrapping a numeral is the
                // one thing worse than reflowing the layout around it — and the
                // reflow above is what makes this safe at every type size.
                .fixedSize()
                .foregroundStyle(item.value == nil ? Palette.secondaryText : Palette.primaryText)
            Text(item.label)
                .dataText(.label)
                .foregroundStyle(Palette.secondaryText)
            if let detail = item.detail {
                Text(detail)
                    .dataText(.label)
                    .foregroundStyle(Palette.secondaryText)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.label.lowercased())
        .accessibilityValue(spokenColumnValue(item))
    }

    /// A column speaks its measurement and then its detail, or says why it is blank.
    /// The detail is only ever spoken beside a value — a spread with no average to
    /// belong to is a figure without its subject.
    private func spokenColumnValue(_ item: ReadoutColumn) -> String {
        guard let spokenValue = item.spokenValue else {
            return String(localized: "not enough contractions yet", comment: "VoiceOver: value of a readout column below its evidence floor, in place of a measurement")
        }
        guard let spokenDetail = item.spokenDetail else { return spokenValue }
        // Already one catalog format string with two positional arguments, not
        // a Swift-side concatenation — a translator can reorder value and detail
        // relative to each other, or choose their own joining punctuation,
        // neither of which a bare `spokenValue + ", " + spokenDetail` would
        // have allowed.
        return String(localized: "\(spokenValue), \(spokenDetail)", comment: "VoiceOver: a readout column's value followed by its detail clause")
    }

    // MARK: Guidance line

    /// The verdict, in the coach voice: measurements first, then the call. It never
    /// commands, and — since decision 0022 §4 — it is **never blank while an episode
    /// is live**. It used to go silent exactly where the averages did, which meant
    /// "we can't say yet" was expressed as nothing at all at the moments a reader
    /// most needs orienting: a drained window forty-seven minutes after the last tap,
    /// a Braxton-Hicks afternoon with no duration average, a contraction being timed
    /// on a screen with three columns of em dashes.
    @ViewBuilder
    private func guidance(_ pattern: LaborPattern, now: Date) -> some View {
        if pattern.episode.isEmpty {
            // Nothing live to speak about; the readout's own copy holds this state.
            EmptyView()
        } else if let guideline = pattern.guideline, guideline.met,
                  let interval = pattern.averageInterval,
                  let duration = pattern.averageDuration,
                  let length = pattern.patternLength {
            // The live shape: the raw verdict is met right now, not merely held.
            // `line1`/`line2` below are already single catalog format strings
            // with positional figure arguments, not Swift concatenation — the
            // same is true of every other banner shape in this function.
            banner(
                headline: Self.metHeadline,
                line1: GuidanceLine(
                    text: String(localized: "Averaging every \(LaborFormat.minutesSeconds(interval)), lasting \(LaborFormat.minutesSeconds(duration)), for \(LaborFormat.hoursMinutes(length)).", comment: "verdict banner, met shape: the three measured figures behind the verdict, printed register"),
                    spoken: String(localized: "Averaging every \(LaborFormat.spoken(interval)), lasting \(LaborFormat.spoken(duration)), for \(LaborFormat.spoken(length)).", comment: "VoiceOver: verdict banner, met shape, spoken form of the three measured figures")
                ),
                line2: GuidanceLine(
                    text: String(localized: "That meets the \(model.rule.label) guideline many providers use. Calling your provider now is reasonable — their instructions come first.", comment: "verdict banner, met shape: states the guideline is met and defers to the provider"),
                    spoken: String(localized: "That meets the \(model.rule.label) guideline many providers use. Calling your provider now is reasonable — their instructions come first.", comment: "VoiceOver: verdict banner, met shape, spoken form of the guideline-met sentence")
                ),
                legs: legRows(interval: interval, duration: duration, length: length, guideline: guideline),
                episode: pattern.episode
            )
            .animation(dawnAnimation, value: pattern.presentedMet)
        } else if pattern.presentedMet,
                  let length = pattern.patternLength,
                  let interval = pattern.averageInterval {
            // The held shape (decision 0025, amended): the latch is holding a
            // verdict that was raw-true within the last ten minutes, through a
            // dip — a dimension wobbling or the evidence floor draining out from
            // under `GuidelineStatus` entirely. `averageInterval` is guaranteed by
            // `PatternAnalysis`'s own no-figures guard; bound with `let` here
            // anyway rather than forced, because a view has no business trusting
            // an invariant it cannot itself enforce.
            banner(
                headline: Self.metHeadline,
                line1: heldFirstLine(pattern, interval: interval, length: length),
                line2: heldSecondLine(pattern, now: now),
                legs: legRows(
                    interval: interval, duration: pattern.averageDuration, length: length,
                    guideline: pattern.guideline
                ),
                episode: pattern.episode
            )
            .animation(dawnAnimation, value: pattern.presentedMet)
        } else if pattern.presentedFastMet,
                  let interval = pattern.averageInterval,
                  let duration = pattern.averageDuration,
                  let length = pattern.patternLength {
            // The fast-met shape (decision 0040): strictly stronger than the rule
            // on frequency and duration, early only on sustained — the same
            // `banner(...)` shell as the met/held shapes above (decision 0036's
            // one-banner grammar), the same three bound figures on line 1, and the
            // legs read honestly off the *ordinary* thresholds via the same
            // `legRows` (APART and LONG both hold — fast-met's own thresholds are
            // strictly stronger than theirs, so whenever fast-met is true the
            // ordinary frequency and duration booleans are already true too — and
            // HOLDING draws open, since the hour is the one thing not met yet).
            //
            // No headline (0040 §Rejected: "a distinct visual register" — a second,
            // louder treatment is the alarm register by the back door). "It looks
            // like time." over an hour that has not been met would overstate what
            // the pattern has actually shown; the sage wash and the figures carry
            // this moment instead, at the same `.voice` weight the other shapes
            // reserve for their headline, just without one.
            // Same already-correct shape as the met banner above: single catalog
            // format strings with positional figure arguments.
            banner(
                headline: nil,
                line1: GuidanceLine(
                    text: String(localized: "Averaging every \(LaborFormat.minutesSeconds(interval)), lasting \(LaborFormat.minutesSeconds(duration)), for \(LaborFormat.hoursMinutes(length)).", comment: "verdict banner, fast-met shape: the three measured figures behind the verdict, printed register"),
                    spoken: String(localized: "Averaging every \(LaborFormat.spoken(interval)), lasting \(LaborFormat.spoken(duration)), for \(LaborFormat.spoken(length)).", comment: "VoiceOver: verdict banner, fast-met shape, spoken form of the three measured figures")
                ),
                line2: GuidanceLine(
                    text: String(localized: "That is closer together than the \(model.rule.label) guideline asks, before the hour it also asks for. Calling your provider now is reasonable — their instructions come first.", comment: "verdict banner, fast-met shape: states the pattern is stronger than the guideline on frequency and duration, ahead of the sustained hour, and defers to the provider"),
                    spoken: String(localized: "That is closer together than the \(model.rule.label) guideline asks, before the hour it also asks for. Calling your provider now is reasonable — their instructions come first.", comment: "VoiceOver: verdict banner, fast-met shape, spoken form of the guideline sentence")
                ),
                legs: legRows(interval: interval, duration: duration, length: length, guideline: pattern.guideline),
                episode: pattern.episode
            )
            .animation(dawnAnimation, value: pattern.presentedFastMet)
        } else {
            // **The call summary belongs here too** (HL-024, F-0044). It used to
            // live only inside `banner(...)`, which renders for the met, held and
            // fast-met shapes — so during the ordinary "not yet" state, which is
            // most of prodromal labor and exactly when an early check-in call
            // happens, there was no way to hand anyone the numbers without leaving
            // for Guidance or opening the Clear Everything dialog and reading past
            // the destructive button to find "Save a copy first…".
            //
            // Quiet by construction: `ForTheCallButton` renders nothing at all
            // until there is an episode to summarise, so an empty screen stays a
            // silence rather than growing a prompt, and the tinted capsule sits
            // below the sentence rather than competing with it.
            VStack(alignment: .leading, spacing: Metrics.space3) {
                let line = partialLine(pattern, now: now)
                Text(line.text)
                    .font(.prose)
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityLabel(line.spoken)
                ForTheCallButton(episode: pattern.episode)
            }
        }
    }

    /// The printed line and its spoken form, built together so they cannot drift.
    private struct GuidanceLine {
        var text: String
        var spoken: String
    }

    /// Shared by the met and held shapes (decision 0036's one-banner grammar) — one
    /// catalog entry, not two independently-translatable copies of the same words.
    private static var metHeadline: String {
        String(localized: "It looks like time.", comment: "verdict banner headline shown when the guideline is met or was recently met — never a diagnosis, never a command")
    }

    /// HL-003 slice 3: the verdict's one moment of dawn — 1.2 s ease-out, well past
    /// the 0.45 s spring that reorders the screen around it, because "light
    /// arriving" and "the layout reflowing" are different gestures and one duration
    /// for both would read as the wash animating a UI transition rather than a lamp
    /// coming on. Nil under Reduce Motion, the same convention every other
    /// `.animation` in this file uses. Nil under `-uitesting` too, and that check is
    /// this animation's own — at 1.2 s a screenshot taken the instant the harness
    /// considers the tree settled can still land mid-fade, where the faster springs
    /// elsewhere are short enough that it never has.
    private var dawnAnimation: Animation? {
        reduceMotion || RuntimeFlags.isUITesting ? nil : .easeOut(duration: 1.2)
    }

    /// The verdict banner's shared shell — same container, same accessibility
    /// treatment, whichever shape fills it. Reorder still keys on
    /// `pattern.presentedMet` alone (decision 0040 §Rejected: the fast shape
    /// borrows this moment rather than earning a reorder of its own), so all
    /// three shapes must look like one banner changing its sentence, not three
    /// different banners.
    ///
    /// The met/held/fast-met shapes all call this (`guidance(_:now:)`'s partial
    /// branch renders its own plain `Text` and never reaches here), so the sage
    /// treatment below is unconditional rather than a parameter — there is no
    /// state this function renders in which it should be withheld. The headline
    /// alone is conditional: `nil` for the fast shape only (decision 0040 §3;
    /// see the doc comment at that call site for why).
    private func banner(
        headline: String?, line1: GuidanceLine, line2: GuidanceLine,
        legs: [LegRow], episode: [Contraction]
    ) -> some View {
        VStack(alignment: .leading, spacing: Metrics.space3) {
            VStack(alignment: .leading, spacing: Metrics.space2) {
                // The headline — the second of `.voice`'s two reserved moments
                // (Typography.swift; the first is "How it works"). Identical
                // across the shapes that carry one on purpose: it hedges, names no
                // diagnosis, commands nothing, and carries no figure (`.voice` sets
                // no monospaced digits, so a recomputing average would jitter
                // under it). The sentence that carries the shape's own difference
                // is the one below it, unchanged by this slice.
                if let headline {
                    Text(headline)
                        .font(.voice)
                        .foregroundStyle(Palette.goTime)
                }
                Text(line1.text)
                    // Prose, not `.voice`: this line is the evidence — three figures in
                    // a sentence — and the serif is reserved for the app speaking as a
                    // person.
                    .font(.claim)
                    .foregroundStyle(Palette.primaryText)
                    .accessibilityLabel(line1.spoken)
                Text(line2.text)
                    .font(.prose)
                    .foregroundStyle(Palette.primaryText)
                    .accessibilityLabel(line2.spoken)
            }
            // The headline and both sentences stay one spoken element; the button
            // below cannot be folded into them or it stops being reachable as an
            // action. That is why the combine moved inward from the card in SP-200
            // rather than being dropped — `LayoutInvariantTests` still finds the
            // verdict by its label, which line1/line2 carry unchanged.
            .accessibilityElement(children: .combine)

            // The rule's three legs, quiet and numerate — a bullet reading state,
            // never a gauge reading magnitude (spec §3's ban on rings holds for a
            // dot too). Each row is its own accessibility element, same split
            // `column(_:)` uses for the readout above. `LegRowView` is shared with
            // History's pinned header (HL-015, `Hushlight/LegRows.swift`) so the two
            // surfaces cannot drift on how a leg renders (F-0012).
            VStack(alignment: .leading, spacing: Metrics.space2) {
                ForEach(legs) { leg in
                    LegRowView(leg: leg)
                }
            }

            // SP-206: the triage script, one tap from the evidence that just
            // justified it — quiet on purpose (tinted, not filled), because the
            // sentence below is still the primary call to action on this banner.
            ForTheCallButton(episode: episode)

            // The sentence above says calling is reasonable. This is the call
            // (SP-200) — absent entirely until a number is stored.
            CallProviderButton()
        }
        .padding(Metrics.space4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Metrics.ctaRadius)
                .fill(Palette.goTimeFill)
        )
        // A hairline, not a second fill: the wash alone reads as a light: the
        // border is what keeps its edge legible at low OLED brightness, the same
        // reason `Palette.raised`'s doc comment gives for never shipping without one.
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.ctaRadius)
                .strokeBorder(Palette.goTime, lineWidth: Metrics.hairline)
        )
    }

    /// The held banner's first line. `interval` always exists here (the no-figures
    /// guard), but `averageDuration` can be gone on its own well above that — the
    /// same sub-floor dip that can drain the whole `GuidelineStatus` can drain the
    /// duration average alone first, since it has the higher floor of the two.
    // Each branch below is already one complete catalog format string with
    // positional figure arguments, not Swift concatenation.
    private func heldFirstLine(
        _ pattern: LaborPattern, interval: Duration, length: Duration
    ) -> GuidanceLine {
        guard let duration = pattern.averageDuration else {
            return GuidanceLine(
                text: String(localized: """
                    Averaging every \(LaborFormat.minutesSeconds(interval)) over \
                    \(pattern.inWindowCount) timed contractions, for \
                    \(LaborFormat.hoursMinutes(length)).
                    """, comment: "verdict banner, held shape, first line, when the duration average has dipped below its own floor: interval and window count, printed register"),
                spoken: String(localized: """
                    Averaging every \(LaborFormat.spoken(interval)) over \
                    \(pattern.inWindowCount) timed contractions, for \
                    \(LaborFormat.spoken(length)).
                    """, comment: "VoiceOver: verdict banner, held shape, first line, when the duration average has dipped below its own floor")
            )
        }
        return GuidanceLine(
            text: String(localized: "Averaging every \(LaborFormat.minutesSeconds(interval)), lasting \(LaborFormat.minutesSeconds(duration)), for \(LaborFormat.hoursMinutes(length)).", comment: "verdict banner, held shape, first line: the three measured figures behind the verdict, printed register"),
            spoken: String(localized: "Averaging every \(LaborFormat.spoken(interval)), lasting \(LaborFormat.spoken(duration)), for \(LaborFormat.spoken(length)).", comment: "VoiceOver: verdict banner, held shape, first line, spoken form of the three measured figures")
        )
    }

    /// The held banner's second line — past tense, and dated (decision 0022): a
    /// verdict the latch is holding through a dip is not happening this instant,
    /// and the reader needs to know how stale "met" is. Mid-contraction there is
    /// nothing to date the dip against, so the clause names that instead.
    ///
    /// **HL-007's line, drawn here.** This was the one call site CLAUDE.md's own
    /// brief names directly: a "dating" clause built as its own `GuidanceLine`
    /// (" — timing one now" / " — last contraction %@ ago"), then spliced into
    /// the middle of a second, outer sentence via `\(dating.text)`. That is a
    /// translatable fragment glued mid-sentence — every language's version of
    /// this clause was forced to start with a leading space and an em dash and
    /// land in exactly this position relative to "use" and "Calling," which a
    /// language whose dating clause reads as a leading adverbial (or wants no
    /// punctuation at all there) had no way to say. Three complete sentences
    /// replace it below — which one to speak is still `pattern.running`'s call
    /// (engine truth), same as before; only the *assembly* changed.
    private func heldSecondLine(_ pattern: LaborPattern, now: Date) -> GuidanceLine {
        let rule = model.rule.label
        if pattern.running != nil {
            let text = String(localized: "That met the \(rule) guideline many providers use — timing one now. Calling your provider now is reasonable — their instructions come first.", comment: "verdict banner, held shape, second line, while a contraction is currently running: states the guideline was met, dated by \"timing one now,\" and defers to the provider")
            return GuidanceLine(text: text, spoken: text)
        }
        if let ended = pattern.episode.compactMap(\.endedAt).max() {
            let gap = Duration.seconds(max(0, now.timeIntervalSince(ended)))
            return GuidanceLine(
                text: String(localized: "That met the \(rule) guideline many providers use — last contraction \(LaborFormat.gap(gap)) ago. Calling your provider now is reasonable — their instructions come first.", comment: "verdict banner, held shape, second line, dated by how long ago the last contraction ended: states the guideline was met and defers to the provider, printed register"),
                spoken: String(localized: "That met the \(rule) guideline many providers use — last contraction \(LaborFormat.spokenGap(gap)) ago. Calling your provider now is reasonable — their instructions come first.", comment: "VoiceOver: verdict banner, held shape, second line, dated by how long ago the last contraction ended, spoken form")
            )
        }
        // Unreachable: `running == nil` over a non-empty episode means every
        // record has ended, so there is always a newest one to date from. Stated
        // as an undated sentence rather than force-unwrapped.
        let text = String(localized: "That met the \(rule) guideline many providers use. Calling your provider now is reasonable — their instructions come first.", comment: "verdict banner, held shape, second line, undated fallback (practically unreachable — an ended episode always has a newest record to date from): states the guideline was met and defers to the provider")
        return GuidanceLine(text: text, spoken: text)
    }

    /// What is measured, and what is missing — in figures.
    ///
    /// The retired template read *"Not at 5-1-1 yet — intervals are longer than
    /// 5-1-1 yet; contractions are shorter than a minute on average."*: two "yet"s,
    /// an interval compared against a rule *name* rather than a number, and a
    /// duration clause sitting three lines under a visible CHECK row it appeared to
    /// contradict. Measured figures say the same thing and can be checked against the
    /// columns above them.
    private func partialLine(_ pattern: LaborPattern, now: Date) -> GuidanceLine {
        let rule = model.rule.label
        let count = pattern.inWindowCount


        // **The irregular early stretch, named** (SP-209, decision 0041). Appended
        // to the partial line and nowhere else — never over a met, held, or
        // fast-met banner, which this function's callers already guarantee — when
        // the spread is wide and the average slow against her rule, both by the
        // pinned 1.5× bounds. `EarlyIrregular` owns the predicate and the copy,
        // package-tested where the medical-claims line can be held.
        let restNote = EarlyIrregular.applies(
            intervalRange: pattern.intervalRange,
            averageInterval: pattern.averageInterval,
            rule: model.rule
        ) ? " " + EarlyIrregular.line : ""
        // 0041 says the note *follows* the partial sentence — whichever one
        // renders. The slow-and-wide state usually takes SP-201's missing-leg
        // branch (frequency is the leg it is missing), so appending only to the
        // figures branch would be a note that never appears exactly where it
        // applies. The first cut did that; the seeded state caught it.
        //
        // `restNote` used to be spliced on with a bare Swift `+` here (two
        // complete, independently-localized sentences concatenated with nothing
        // between them but whatever leading space `restNote` itself carried) —
        // `missingLegLine` now takes it as a real trailing argument and threads
        // it through each of its own templates instead, the same shape the
        // figures branch immediately below already used (its own trailing
        // `\(restNote)` inside one catalog format string, never appended after
        // the fact). One thread, no post-hoc concatenation, either way the note
        // reaches the reader.
        if let line = missingLegLine(pattern, restNote: restNote) { return line }

        if let interval = pattern.averageInterval {
            if let duration = pattern.averageDuration {
                return GuidanceLine(
                    text: String(localized: """
                        Not at \(rule) yet — averaging \
                        \(LaborFormat.minutesSeconds(interval)) apart and \
                        \(LaborFormat.minutesSeconds(duration)) long over \
                        \(count) timed contractions.\(restNote)
                        """, comment: "partial-pattern line: neither leg is missing yet, but the pattern hasn't held the guideline's window — states the measured interval and duration, printed register"),
                    spoken: String(localized: """
                        Not at \(rule) yet. Averaging \
                        \(LaborFormat.spoken(interval)) apart and \
                        \(LaborFormat.spoken(duration)) long over \
                        \(count) timed contractions.\(restNote)
                        """, comment: "VoiceOver: partial-pattern line, spoken form of the interval-and-duration state")
                )
            }
            // Spacing is measurable, length is not — a forgotten stop or a window
            // that holds fewer than three finished contractions. Naming which half is
            // missing is what the silence never did.
            return GuidanceLine(
                text: String(localized: """
                    Not at \(rule) yet — averaging \
                    \(LaborFormat.minutesSeconds(interval)) apart over \(count) timed \
                    contractions; not enough finished ones yet to average their length.
                    """, comment: "partial-pattern line: spacing is measurable, duration is not — states the measured interval and that duration has no average yet"),
                spoken: String(localized: """
                    Not at \(rule) yet. Averaging \(LaborFormat.spoken(interval)) apart \
                    over \(count) timed contractions. Not enough finished ones yet to \
                    average their length.
                    """, comment: "VoiceOver: partial-pattern line, spoken form of the spacing-measurable-duration-not state")
            )
        }

        if pattern.running != nil {
            let text = count > 0
                ? String(localized: "Timing this contraction — \(count) in the last hour.", comment: "partial-pattern line while a contraction is running, with other contractions already in the trailing hour")
                : String(localized: "Timing this contraction — nothing else in the last hour.", comment: "partial-pattern line while a contraction is running, with nothing else in the trailing hour")
            return GuidanceLine(text: text, spoken: text)
        }

        if let ended = pattern.episode.compactMap(\.endedAt).max() {
            let gap = Duration.seconds(max(0, now.timeIntervalSince(ended)))
            return GuidanceLine(
                text: String(localized: "Last contraction \(LaborFormat.gap(gap)) ago — not enough in the last hour to average.", comment: "partial-pattern line: no contraction running, naming how long ago the last one ended, printed register"),
                spoken: String(localized: "Last contraction \(LaborFormat.spokenGap(gap)) ago. Not enough in the last hour to average.", comment: "VoiceOver: partial-pattern line, spoken form of the last-contraction-ago state")
            )
        }

        // Unreachable: a live episode holds at least one record, and every record is
        // either running or finished. Stated rather than force-unwrapped.
        let text = String(localized: "Not enough in the last hour to average.", comment: "partial-pattern line fallback (practically unreachable — a live episode always has a running or finished record to date from)")
        return GuidanceLine(text: text, spoken: text)
    }

    /// **Which leg of the rule is missing** (SP-201), when exactly one is.
    ///
    /// The engine has always computed the verdict per dimension; the screen never
    /// read it, so a pattern four minutes apart and a minute long, twenty-three
    /// minutes in, said only "Not at 5-1-1 yet" and left a reader at 3am doing
    /// three-way arithmetic against a rule she is holding in her head. Each branch
    /// below names the two dimensions that are there and states the missing one as a
    /// **measured figure against the rule's own number** — never a countdown, never
    /// an estimate of when it will be met, because the pattern is not a trajectory
    /// and this app does not predict.
    ///
    /// Two or three legs missing keeps the older line: naming two absences is a list,
    /// not an orientation, and the figures already say it.
    ///
    /// Each comparison is drawn from the quantity the boolean itself reads, so the
    /// sentence cannot contradict the verdict beside it:
    ///   - frequency is a **share** of in-window gaps under the threshold, not the
    ///     mean (decision 0023 §3), so the copy prints the *range* — which comes from
    ///     the same `intervals` array the share counts — and a mean that looks
    ///     passing beside a failing share can never be printed as the reason;
    ///   - duration prints the average the boolean reads, and names the rule as
    ///     stated ("about a minute") rather than the 50 s allowance (decision 0023
    ///     §1) — safe here because this branch only renders when the average is
    ///     *under* the allowance, so the printed figure is visibly under a minute;
    ///   - sustained prints `sustainedEvidence`, the unbroken stretch — the one
    ///     figure that covers both ways this leg fails (too young, or a break in it)
    ///     and the same quantity the tick tape fills from, so bar and words agree.
    ///
    /// Each branch below was already one complete catalog format string with
    /// positional figure arguments — the "HL-007 will restructure" flag that
    /// used to sit over each of them named the wrong culprit; `partialLine`'s own
    /// post-hoc `line.text + restNote` concatenation was the actual violation.
    /// `restNote` is threaded through as a real trailing argument now, the same
    /// position `partialLine`'s own figures-only branch already threads it
    /// through, so every template here can carry it without a caller gluing
    /// anything onto the result afterward.
    private func missingLegLine(_ pattern: LaborPattern, restNote: String) -> GuidanceLine? {
        guard let status = pattern.guideline else { return nil }
        let rule = model.rule
        let label = rule.label

        switch (status.frequencyMet, status.durationMet, status.sustainedMet) {
        case (true, true, false):
            // The documented one-second seam (`PatternAnalysis`): a break sitting
            // exactly on the window edge reads a full hour of evidence while
            // `sustainedMet` is already false. Printing "unbroken for 1 H … asks for
            // an hour" would be a sentence contradicting itself, so that instant
            // falls through to the figures-only line instead.
            guard pattern.sustainedEvidence < rule.sustainedWindow else { return nil }
            // `gap`, not `hoursMinutes`: seconds after a break the unbroken stretch
            // is under a minute, and "unbroken for 0 M" is the zero-as-measurement
            // the em dashes exist to prevent (decision 0022 §7).
            return GuidanceLine(
                text: String(localized: """
                    Not at \(label) yet — spacing and length are there; this stretch \
                    has been unbroken for \(LaborFormat.gap(pattern.sustainedEvidence)), \
                    and the guideline asks for an hour.\(restNote)
                    """, comment: "partial-pattern line: only the sustained-hour leg is missing — spacing and duration already meet the guideline, with a trailing early-irregular-stretch note when it applies"),
                spoken: String(localized: """
                    Not at \(label) yet. This stretch has been unbroken for \
                    \(LaborFormat.spokenGap(pattern.sustainedEvidence)); the guideline \
                    asks for an hour. Spacing and length are there.\(restNote)
                    """, comment: "VoiceOver: partial-pattern line, spoken form, only the sustained-hour leg missing, with a trailing early-irregular-stretch note when it applies")
            )

        case (false, true, true):
            // Guaranteed non-nil wherever `guideline` exists — both clear the same
            // two-interval floor — but bound rather than forced: a view has no
            // business trusting an invariant it cannot itself enforce.
            guard let range = pattern.intervalRange else { return nil }
            return GuidanceLine(
                text: String(localized: """
                    Not at \(label) yet — length and the hour are there; spacing runs \
                    \(LaborFormat.range(range)), and the guideline asks for \
                    \(LaborFormat.minutesSeconds(rule.intervalThreshold)) or closer.\(restNote)
                    """, comment: "partial-pattern line: only the spacing/frequency leg is missing — duration and the sustained hour already meet the guideline, with a trailing early-irregular-stretch note when it applies"),
                spoken: String(localized: """
                    Not at \(label) yet. Spacing runs \(LaborFormat.spoken(range.lowerBound)) \
                    to \(LaborFormat.spoken(range.upperBound)); the guideline asks for \
                    \(LaborFormat.spoken(rule.intervalThreshold)) or closer. Length and \
                    the hour are there.\(restNote)
                    """, comment: "VoiceOver: partial-pattern line, spoken form, only the spacing/frequency leg missing, with a trailing early-irregular-stretch note when it applies")
            )

        case (true, false, true):
            guard let duration = pattern.averageDuration else { return nil }
            return GuidanceLine(
                text: String(localized: """
                    Not at \(label) yet — spacing and the hour are there; contractions \
                    are averaging \(LaborFormat.minutesSeconds(duration)), and the \
                    guideline asks for about a minute.\(restNote)
                    """, comment: "partial-pattern line: only the duration leg is missing — spacing and the sustained hour already meet the guideline, with a trailing early-irregular-stretch note when it applies"),
                spoken: String(localized: """
                    Not at \(label) yet. Contractions are averaging \
                    \(LaborFormat.spoken(duration)); the guideline asks for about a \
                    minute. Spacing and the hour are there.\(restNote)
                    """, comment: "VoiceOver: partial-pattern line, spoken form, only the duration leg missing, with a trailing early-irregular-stretch note when it applies")
            )

        default:
            return nil
        }
    }

    // MARK: The slip strip

    /// **Catching the mis-tap where it happens** (SP-203). A double tap records
    /// eleven seconds and says nothing; fixing it meant knowing it was wrong,
    /// navigating to History, and swipe-deleting mid-labor.
    ///
    /// Deliberately not an alert: it interrupts nothing, it is one line and one
    /// button above the slab, and the next start-tap lands on a slab that has not
    /// moved. Deliberately not automatic either — the app flags and offers, it never
    /// deletes a record on its own, here or on the over-three-minute side.
    @ViewBuilder
    private var slipStrip: some View {
        if let slip, let duration = slip.duration {
            // Side by side while it fits; stacked at accessibility sizes, where the
            // sentence needs the whole width and sharing it with the button squeezed
            // the text into a 181-pt column that clipped (caught by the AX5 audit).
            // Same treatment the header already takes at those sizes.
            // On `inputFill` (this strip's own background, below), not the room —
            // undarkened `secondaryText` measures 4.42:1 there in light
            // appearance, under AA (HL-019).
            let sentence = Text("Recorded \(LaborFormat.minutesSeconds(duration)) — likely a slip.", comment: "slip strip: names the recorded duration and states it reads as a mis-tap, above a Delete button")
                .font(.prose)
                .foregroundStyle(Palette.secondaryTextOnFill)
                .accessibilityLabel(
                    String(localized: "Recorded \(LaborFormat.spoken(duration)) — likely a slip. It is already out of the averages.", comment: "VoiceOver: spoken form of the slip strip's sentence, adding that the record is already excluded from the averages")
                )
            // No `role: .destructive` — decision 0046. This capsule is the app's
            // own chrome, and red is not in its palette; at accessibility sizes the
            // red made this the loudest element on a screen whose whole job at that
            // moment is to be calm about a mis-tap. The weight is in the words above
            // it, and Undo is one screen away.
            let delete = Button("Delete") {
                model.delete(slip)
                corrections += 1
                self.slip = nil
            }
                .font(.prose.weight(.semibold))
                .frame(minHeight: Metrics.minimumTapTarget)
                .accessibilityHint(String(localized: "Removes the slip. Undo is in History.", comment: "VoiceOver hint for the slip strip's Delete button"))

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: Metrics.space2) {
                        sentence
                        delete
                    }
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: Metrics.space3) {
                        sentence
                        Spacer(minLength: 0)
                        delete
                    }
                }
            }
            .padding(.horizontal, Metrics.space4)
            .padding(.vertical, Metrics.space2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Palette.inputFill,
                in: RoundedRectangle(cornerRadius: Metrics.ctaRadius)
            )
            .transition(.opacity)
            // Self-dismissing, because an offer that has to be dismissed is a second
            // thing to do mid-contraction. Not while VoiceOver is on: a strip that
            // vanishes on a timer is one she may never reach, so there it waits for
            // the next tap to replace it.
            .task(id: slip.id) {
                guard !voiceOverEnabled else { return }
                try? await Task.sleep(for: .seconds(Self.slipStripLifetime))
                if !Task.isCancelled { self.slip = nil }
            }
        }
    }

    /// Long enough to read one line and reach for the button, short enough that it is
    /// gone before the next contraction.
    private static let slipStripLifetime = 10

    /// Reads what the tap just did from the model's own undo record rather than from
    /// a snapshot taken around it — `undoAction` is the store's answer to "what was
    /// the last thing that happened", and a start-tap can never be mistaken for an
    /// end-tap by reading it.
    private func noteSlipIfJustRecorded() {
        guard case .ended(let id) = model.undoAction,
              let record = model.contractions.first(where: { $0.id == id }),
              record.suspicion == .tooShort
        else {
            // Any other tap clears a standing offer: the strip describes the last
            // record, and the last record has just changed.
            slip = nil
            return
        }
        slip = record
    }

    // MARK: Timeline

    @ViewBuilder
    private func timelineSection(_ pattern: LaborPattern, now: Date) -> some View {
        if !pattern.episode.isEmpty {
            EpisodeTimeline(episode: pattern.episode, now: now)
        }
    }

    // MARK: The slab

    /// **What "sits below the disc" becomes when there is no disc.** The old boolean
    /// answered a geometry question: the circle had a fixed diameter (216–280 pt),
    /// the caption was the widest thing inside it, and past accessibility sizes the
    /// caption had to step outside the circle or wrap mid-word against its arc. The
    /// slab has no such ceiling — it grows for whatever it holds (§WHAT TO BUILD 1),
    /// so the caption never has to escape it, and the escape-and-recolour dance
    /// `slab(now:)` used to do against `.bar` is gone with the shape that forced it.
    ///
    /// What survives is the one part of the old boolean that was never about the
    /// circle's shape: SP-204's two-sentence running-long notice, and the caption at
    /// accessibility sizes, are the cases long enough to reliably wrap to a second
    /// line — and a wrapped caption wants more air above it than a one-liner does, so
    /// `slab(now:)` reads this for spacing rather than position. Renamed to say that
    /// rather than a place that no longer exists.
    private func captionMayWrap(now: Date) -> Bool {
        dynamicTypeSize.isAccessibilitySize || isRunningLong(now: now)
    }

    /// **The hint yields to the correction.** At accessibility sizes the bottom bar
    /// has to hold the slip strip, the slab, and this hint at once, and a slab with
    /// no ceiling would still rather not: the hint repeats what the label already
    /// says, VoiceOver reads the action from the button's own label and hint
    /// regardless, and it is back in ten seconds.
    private var showsCaption: Bool {
        !(dynamicTypeSize.isAccessibilitySize && slip != nil)
    }

    /// **Naming the forgotten timer while it is still running** (SP-204). Past three
    /// minutes the hint stops being a hint: the most likely explanation for a
    /// contraction still going is that the end tap never landed, and the screen says
    /// so in the same words it would use afterwards. An honest restatement of what
    /// the engine already does — no auto-cap, no auto-end, no verdict about her.
    private func caption(now: Date) -> String {
        // The two-sentence form still moves out to the scroll content at
        // accessibility sizes (`runningLongNotice`) rather than growing the bar to
        // hold it — not because the slab cannot fit it (it can, now), but because a
        // pinned bar that grows to several hundred points at AX5 pushes the readout
        // and the verdict further below the fold, which decision 0027 exists to
        // prevent. The bar holds the control at a size that leaves room to scroll to;
        // the scrolling region holds the prose.
        if isRunningLong(now: now) && !dynamicTypeSize.isAccessibilitySize {
            return LaborFormat.runningLongCaption()
        }
        return model.isRunning
            ? String(localized: "Tap when it ends", comment: "caption under the slab's action word while a contraction is running")
            : String(localized: "Tap when it begins", comment: "caption under the slab's action word while idle")
    }

    /// The accessibility-size home for SP-204's sentence. Rendered above the readout,
    /// under the verdict — the two things on this screen that are prose rather than
    /// instrument, in the order a reader needs them.
    @ViewBuilder
    private func runningLongNotice(now: Date) -> some View {
        if isRunningLong(now: now) && dynamicTypeSize.isAccessibilitySize {
            Text(LaborFormat.runningLongCaption())
                .font(.prose)
                .foregroundStyle(Palette.secondaryText)
                .accessibilityLabel(LaborFormat.spokenRunningLong())
        }
    }

    private func isRunningLong(now: Date) -> Bool {
        model.running?.isRunningLong(at: now) ?? false
    }

    /// The category's circle (SP-187) becomes the identity's slab (HL-003 slice 1,
    /// decision 0036): full-width, bottom-anchored, sized by its content rather than
    /// a diameter — content grows the bar (`Self.slabMinHeight` is a floor, not a
    /// target) instead of clipping inside it. The whole lower third is the target,
    /// answering the same walkthrough finding that shipped the circle in the first
    /// place: a centred control wastes the thumb zone.
    ///
    /// The label is always the ACTION word now that the live figure has moved to
    /// `liveHero(now:)` — "Start" idle, "End" running — where the disc used to
    /// substitute the ticking numeral for exactly that word while a contraction ran.
    ///
    /// SP-188's light survives the shape change: gradient depth from the one tint
    /// while idle, a slow breath, a flat quiet fill while running (`slabFill`). All
    /// of it stands down under Reduce Motion.
    private func slab(now: Date, fillsHeight: Bool = false) -> some View {
        // Running rests on `Palette.inputFill`, a neutral surface — `primaryText`
        // is the token that already carries every other reading on that fill (the
        // verdict banner, the slip strip): measured 11.71:1 dark, 11.05:1 light.
        // Idle rests on the ember gradient below, which needs the ink that was
        // `Color.white`: `onEmber`, verified against both gradient stops by
        // `PaletteContrastTests` (11.25:1 / 7.43:1 dark, 5.53:1 / 7.38:1 light).
        let ink = model.isRunning ? Palette.primaryText : Palette.onEmber

        return Button {
            model.tap(at: now)
            noteSlipIfJustRecorded()
        } label: {
            // The extra gap is `captionMayWrap`'s one remaining job: a caption that
            // may run two lines wants more air between it and the action word above
            // it than a caption that never does — harmless to a single line, which
            // ignores `multilineTextAlignment(.center)` the same way.
            VStack(spacing: captionMayWrap(now: now) ? Metrics.space3 : Metrics.space2) {
                Text(model.isRunning ? "End" : "Start", comment: "the slab's action word — End while a contraction is running, Start while idle")
                    .font(.screenTitle)
                if showsCaption {
                    Text(caption(now: now))
                        .font(.prose)
                        .multilineTextAlignment(.center)
                }
            }
            .foregroundStyle(ink)
            .padding(.horizontal, Metrics.space4)
            .padding(.vertical, Metrics.space4)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Self.slabMinHeight, maxHeight: fillsHeight ? .infinity : nil)
            .background(slabFill)
            // The circle was the *look*; the whole bar was always the target, and
            // the slab keeps that contract rather than inheriting a new one — the
            // frame above already claims the full width and floor height, so
            // shaping the tap region to it leaves no dead corners either side, on
            // the one surface whose promise is that nothing requires aim,
            // mid-contraction, one-handed, in the dark. Both modifiers stay inside
            // the label: a frame applied after `.buttonStyle` only centers the
            // button, it does not widen a shape already declared.
            .contentShape(Rectangle())
        }
        .buttonStyle(SlabButtonStyle())
        .breathing(while: !model.isRunning && !reduceMotion)
        // **Which way the timer went, felt** (SP-202). One `.impact(.heavy)` fired on
        // both edges of `isRunning`, so eyes shut she knew a tap had landed and not
        // whether it had started or ended a contraction — the ambiguity behind both
        // failure modes the walkthrough found: an 11-second record from a double tap,
        // and a timer left running for 25 minutes. `.start` and `.stop` are the
        // system's own timer textures, the ones Stopwatch uses.
        //
        // The trigger stays the model's state rather than a tap counter: the
        // lock-screen intent writes the same state without touching this button, and
        // a counter would only be felt for taps this view happened to own.
        .sensoryFeedback(trigger: model.isRunning) { _, isRunning in
            isRunning ? .start : .stop
        }
        .accessibilityLabel(model.isRunning
            ? String(localized: "End contraction", comment: "VoiceOver label for the slab button while a contraction is running")
            : String(localized: "Start contraction", comment: "VoiceOver label for the slab button while idle"))
        // HL-048. The label above is the one a screen reader speaks and is therefore
        // translated; a test that matched on it would only work in English. The
        // identifier is stable across all nine languages and invisible to VoiceOver.
        .accessibilityIdentifier("timer.slab")
        // The live elapsed time is state, not a description of the tap — it belongs
        // in the value VoiceOver re-reads on demand, not the hint, which HIG reserves
        // for what the action does and which used to carry this, mutating every
        // second under the 1 Hz TimelineView.
        // The value is read when she asks for it, which is why SP-204's warning rides
        // here rather than on an announcement: a `TimelineView` ticking once a second
        // would otherwise interrupt her once a second to say the same thing.
        .accessibilityValue(spokenButtonValue(now: now))
        .accessibilityHint(
            model.isRunning
                ? String(localized: "Ends the contraction being timed", comment: "VoiceOver hint for the slab button while a contraction is running")
                : String(localized: "Starts timing a contraction", comment: "VoiceOver hint for the slab button while idle")
        )
    }

    /// Elapsed, plus SP-204's warning once the record has run past three minutes.
    /// One string rather than a second element: VoiceOver reads a value when asked,
    /// so this reaches her on demand instead of interrupting once a second.
    private func spokenButtonValue(now: Date) -> String {
        guard model.isRunning, let since = model.runningSince else { return "" }
        let elapsed = LaborFormat.spoken(.seconds(max(0, now.timeIntervalSince(since))))
        guard isRunningLong(now: now) else { return elapsed }
        return "\(elapsed). \(LaborFormat.spokenRunningLong())"
    }

    /// Depth from the single tint: lighter toward the top, deeper at the base, and a
    /// quiet halo. Running swaps to the flat quiet fill — the two fills are how the
    /// slab reads live without a word (§WHAT TO BUILD 1); the shape moved from
    /// `Circle()` to a continuous-corner `RoundedRectangle`, the fills and the shadow
    /// did not.
    ///
    /// SP-187's ring (`Circle().strokeBorder(.emberLive, …)`) does not carry over: it
    /// existed to mark the live state on a shape whose fill alone read as one flat
    /// colour front to back, and the slab's fill already changes wholesale between
    /// idle and running. A stroke earning its place on a rectangle instead of a
    /// circle is a decision for whichever later slice actually needs it, not a
    /// default to preserve.
    @ViewBuilder
    private var slabFill: some View {
        let shape = RoundedRectangle(cornerRadius: Metrics.slabRadius, style: .continuous)
        if model.isRunning {
            shape.fill(Palette.inputFill)
        } else {
            shape
                .fill(
                    // Two named stops rather than a mix computed here (decision 0034).
                    // The mix this replaced was calibrated for white ink on system
                    // blue, where darkening the fill *raised* contrast; under
                    // `onEmber` the relationship inverts, and the old bottom stop
                    // measured 3.70:1 against the ink actually drawn on it. The
                    // tokens carry the measurement and `PaletteContrastTests` holds
                    // them — a runtime mix is the one colour that suite cannot see.
                    // Still lit from above in both appearances.
                    LinearGradient(
                        colors: [Palette.emberSlabTop, Palette.emberSlabBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Palette.tint.opacity(0.35), radius: 24, y: 6)
        }
    }
}

extension Duration {
    /// Bridging for gauge arithmetic; screens never do date math beyond this.
    var timeIntervalValue: TimeInterval {
        TimeInterval(components.seconds) + TimeInterval(components.attoseconds) / 1e18
    }
}

/// Press feedback on the slab (SP-187's circle, before HL-003): the scale under
/// normal motion, an opacity step substituted under Reduce Motion — the same pair
/// `CapsuleButtonStyle` already uses, and a substitution rather than a removal
/// because feedback is not decoration.
///
/// `.plain` left the one control on this screen that gets pressed in the dark with
/// nothing at all between touch-down and the haptic on release. HIG names a missing
/// press state as the most common omission in custom controls, and this is the
/// custom control the whole app is.
private struct SlabButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!reduceMotion && configuration.isPressed ? Metrics.pressedScale : 1)
            .opacity(reduceMotion && configuration.isPressed ? Metrics.pressedOpacity : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
            // A pointer on iPad (HL-058b): the system's own lift on the one control.
            .hoverEffect(.automatic)
    }
}

extension View {
    /// A slow breath — four seconds a cycle, barely there. The idle slab is the
    /// one living thing on a still screen; the animation says "ready", never
    /// "hurry". Inert when `active` is false, including under Reduce Motion.
    @ViewBuilder
    func breathing(while active: Bool) -> some View {
        if active {
            phaseAnimator([false, true]) { content, phase in
                content
                    .scaleEffect(phase ? 1.02 : 1.0)
                    .opacity(phase ? 1.0 : 0.96)
            } animation: { _ in
                .easeInOut(duration: 2.0)
            }
        } else {
            self
        }
    }

    /// `.scrollEdgeEffectStyle` is iOS 26 and later, and so is the fade it opts out
    /// of: below 26 there is no automatic scroll-edge blend, so the modifier's
    /// absence *is* the `.hard` behaviour the comment at the call site asked for.
    /// Hence a guard rather than a deployment floor — the older OS already renders
    /// the honest edge, and HL-007's promise holds on both sides of 26 (HL-038).
    @ViewBuilder
    func hardBottomScrollEdge() -> some View {
        if #available(iOS 26.0, *) {
            scrollEdgeEffectStyle(.hard, for: .bottom)
        } else {
            self
        }
    }
}

#Preview {
    TimerScreen()
        .environment(LaborModel())
        .environment(KeyboardIntents())
}
