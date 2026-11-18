import DesignKit
import LaborKit
import SwiftUI
import UIKit

/// What the guideline means, which variant applies, and the situations where the
/// pattern doesn't matter and the answer is to call now.
///
/// The register is the ecosystem's coach voice: numerate, direct, calm. This app
/// measures and reports — the copy below is the one place it talks, and it defers
/// to the provider in every paragraph, because that is both the honest position
/// and the App Review line: no diagnosis, no commands.
struct GuidanceScreen: View {
    /// HL-057: owned here for the `ViewThatFits` pair below — see the comment there.
    @State private var callRefused = false

    @Environment(LaborModel.self) private var model

    /// Only the provider field takes focus on this screen, and it needs a way out:
    /// see `providerField`.
    @FocusState private var providerFieldFocused: Bool

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.space6) {
                rulePicker($model)
                providerField($model)
                heartbeat
                callNow
                disclaimer
            }
            .padding(.horizontal, Metrics.screenMargin)
            .padding(.vertical, Metrics.space5)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Palette.screen)
        .navigationTitle("Guidance")
    }

    // MARK: The rule

    private func rulePicker(_ model: Bindable<LaborModel>) -> some View {
        VStack(alignment: .leading, spacing: Metrics.space3) {
            SectionHeader(label: String(localized: "Your guideline", comment: "section header above the guideline-rule picker on the Guidance screen"))

            Picker("Guideline", selection: model.rule) {
                ForEach(GuidelineRule.allCases) { rule in
                    Text(rule.label).tag(rule)
                }
            }
            .pickerStyle(.segmented)

            Text(explainer(for: model.wrappedValue.rule))
                .font(.prose)
                .foregroundStyle(Palette.secondaryText)

            // Decision 0023 §1: the measurement allowance is disclosed, not silent.
            // The boolean checks a recorded average against 50 s while the screen
            // prints the exact figure, and a reader who noticed "0:55" beside a met
            // verdict deserves the reason rather than a contradiction. Stated as
            // mechanics, in the ecosystem's register — no instruction, no reassurance.
            Text("Timing starts at the tap, and a tap comes a few seconds after the contraction does — so recorded lengths run a little behind the felt minute. The duration check allows for that; the figures on the timer stay exactly what was recorded.", comment: "Guidance screen: explains the measurement allowance behind the duration check, so a 0:55 average beside a met verdict isn't read as a contradiction")
                .font(.prose)
                .foregroundStyle(Palette.secondaryText)

            Text("Providers instruct differently — second babies, distance to the hospital, and your history all move this. If yours gave you a rule, set it here and follow theirs.", comment: "Guidance screen: explains why the app offers more than one guideline rule to choose from")
                .font(.prose)
                .foregroundStyle(Palette.secondaryText)
        }
    }

    /// This was already one complete catalog format string — `rule.label` and
    /// `minutes` are two positional arguments in one sentence, not fragments a
    /// Swift `+` assembles — so nothing about its *shape* needed restructuring.
    /// `minutes` is a real `Int`, interpolated directly, so it keys into the
    /// catalog as `%lld` and is wired through `variations.plural` for whatever
    /// language needs it — every `GuidelineRule` case is 3, 4, or 5 minutes
    /// today (`PatternAnalysis.swift`), so English's own `one` category is
    /// unreachable in practice, but a translated language's own CLDR plural
    /// rule may still carve out a distinct form for "few" at exactly these
    /// values, which the machinery now supports even though English never
    /// exercises it.
    private func explainer(for rule: GuidelineRule) -> String {
        let minutes = Int(rule.intervalThreshold.components.seconds) / 60
        return String(localized: "\(rule.label): contractions every \(minutes) minute or closer, each lasting about a minute, sustained for an hour without a long break in it. The timer reads all three from your taps and says so when the pattern is there.", comment: "Guidance screen: states the selected guideline rule in full sentence form, naming the interval, duration and sustained-window figures it uses — catalog plural entry on the minutes argument")
    }

    // MARK: The provider's number

    /// The field that makes "calling your provider now is reasonable" actionable
    /// (SP-200). Optional, unprompted, and local: it sits in this device's defaults
    /// beside the rule, is never read by anything that leaves the phone, and an
    /// empty field means every Call button in the app simply does not exist.
    private func providerField(_ model: Bindable<LaborModel>) -> some View {
        VStack(alignment: .leading, spacing: Metrics.space3) {
            SectionHeader(label: String(localized: "Your provider or L&D number", comment: "section header above the provider phone number field on the Guidance screen"))

            TextField("Optional", text: model.providerNumber)
                .font(.prose)
                .foregroundStyle(Palette.primaryText)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .focused($providerFieldFocused)
                // A phone pad has **no return key**, so there is no submit action to
                // label — the toolbar below is the only way off this keyboard, and
                // without it the pad sits over half the screen until she navigates
                // away. The scroll dismissal is the second route, for a thumb that
                // never finds the toolbar.
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { providerFieldFocused = false }
                    }
                }
                .padding(Metrics.space3)
                .frame(minHeight: Metrics.minimumTapTarget, alignment: .leading)
                .background(
                    Palette.inputFill,
                    in: RoundedRectangle(cornerRadius: Metrics.ctaRadius)
                )
                .accessibilityLabel(String(localized: "Your provider or labor and delivery number", comment: "VoiceOver label for the provider phone number text field on the Guidance screen"))

            Text("Stays on this phone. Once it is set, a Call button appears beside the verdict on the timer and under the list below — so the call this app keeps recommending is one tap, not a search through Contacts at 3am.", comment: "Guidance screen: explains what setting the provider number unlocks — a one-tap Call button")
                .font(.prose)
                .foregroundStyle(Palette.secondaryText)
        }
    }

    // MARK: Heartbeat

    /// HL-012's one setting. It lives here rather than in a Settings screen the app
    /// does not have and should not grow — Guidance is where the app's few
    /// adjustments already live, beside the guideline and the number.
    @AppStorage("heartbeatWhileTiming") private var heartbeatWhileTiming = false
    /// HL-017's opt-in, beside HL-012's — the two quiet aids share one home.
    @AppStorage("breathPacerWhileTiming") private var breathPacerWhileTiming = false

    private var heartbeat: some View {
        VStack(alignment: .leading, spacing: Metrics.space3) {
            SectionHeader(label: String(localized: "Heartbeat while timing", comment: "section header above the heartbeat-pulse toggle on the Guidance screen"))
            Toggle(isOn: $heartbeatWhileTiming) {
                Text("A soft pulse every 15 seconds while a contraction is timed", comment: "label beside the heartbeat toggle on the Guidance screen")
                    .font(.prose)
                    .foregroundStyle(Palette.primaryText)
            }
            .tint(Palette.tint)
            .frame(minHeight: Metrics.minimumTapTarget)
            Text("So the phone can sit face-down or in a pocket and still be trusted. Off unless you want it; quiet in Low Power Mode.", comment: "Guidance screen: explains why the heartbeat pulse exists and when it stays quiet")
                .font(.prose)
                .foregroundStyle(Palette.secondaryText)

            SectionHeader(label: String(localized: "Breath pacer while timing", comment: "section header above the breath-pacer toggle on the Guidance screen"))
            Toggle(isOn: $breathPacerWhileTiming) {
                Text("Counted breaths under the timer — in for 4, out for 6", comment: "label beside the breath-pacer toggle on the Guidance screen")
                    .font(.prose)
                    .foregroundStyle(Palette.primaryText)
            }
            .tint(Palette.tint)
            .frame(minHeight: Metrics.minimumTapTarget)
            Text("A slow cadence to breathe with while a contraction is timed. The glow keeps the same rhythm.", comment: "Guidance screen: explains what the breath pacer does while a contraction is timed")
                .font(.prose)
                .foregroundStyle(Palette.secondaryText)
        }
    }

    // MARK: Call now

    private var callNow: some View {
        VStack(alignment: .leading, spacing: Metrics.space3) {
            // On `inputFill` (the card this section fills), not the room — see
            // `SectionHeader.init(onFill:)` (HL-019).
            SectionHeader(label: String(localized: "Call right away — pattern aside", comment: "section header for the always-call card on the Guidance screen, listing situations that warrant a call regardless of the timed pattern"), onFill: true)

            VStack(alignment: .leading, spacing: Metrics.space2) {
                bullet(String(localized: "Your water breaks — note the time and the color of the fluid.", comment: "Guidance screen: call-right-away bullet — water breaking"))
                bullet(String(localized: "Bleeding, more than spotting.", comment: "Guidance screen: call-right-away bullet — bleeding"))
                bullet(String(localized: "The baby is moving less than usual.", comment: "Guidance screen: call-right-away bullet — reduced fetal movement"))
                bullet(String(localized: "Regular contractions before 37 weeks.", comment: "Guidance screen: call-right-away bullet — preterm labor"))
                bullet(String(localized: "Anything that feels wrong to you.", comment: "Guidance screen: call-right-away bullet — catch-all"))
            }

            Text("None of these wait for a timer. Call your provider or labor and delivery directly.", comment: "Guidance screen: closes the call-right-away card, stating these situations don't wait for the pattern")
                .font(.prose)
                .foregroundStyle(Palette.primaryText)

            // Renders only when a number is stored — see `CallProviderButton`.
            // Renders only when there is a current episode to summarize — see
            // `ForTheCallButton`. Beside the provider entry rather than below the
            // whole card: both are "make the call easier," read together. Side by
            // side while it fits; stacked at accessibility sizes, where a phone
            // number capsule and a second capsule beside it is the layout that
            // clips (§8: reflow, never truncation).
            // The refusal flag lives here, not in the button: the fallback widens
            // the row, `ViewThatFits` may switch branches, and a button instance
            // born in the other branch would forget it had just been refused.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Metrics.space3) {
                    CallProviderButton(showsNumber: true, refused: $callRefused)
                    ForTheCallButton(episode: currentEpisode)
                }
                VStack(alignment: .leading, spacing: Metrics.space3) {
                    CallProviderButton(showsNumber: true, refused: $callRefused)
                    ForTheCallButton(episode: currentEpisode)
                }
            }
            .padding(.top, Metrics.space1)
        }
        .padding(Metrics.space4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Palette.inputFill,
            in: RoundedRectangle(cornerRadius: Metrics.ctaRadius)
        )
    }

    /// The stretch currently being timed, oldest first — the same figures the
    /// timer screen judges, read cold rather than carried in from `LaborPattern`
    /// (Guidance has no `TimelineView` of its own, and does not need one to answer
    /// "what episode is live right now").
    private var currentEpisode: [Contraction] {
        PatternAnalysis.episodes(model.contractions).last ?? []
    }

    /// Takes an already-localized `String` (every call site wraps its literal in
    /// `String(localized:)`) — `Text(text)` here is the verbatim-`String`
    /// initializer, not the auto-keying `LocalizedStringKey` one, because `text`
    /// is a variable, not a literal.
    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.space2) {
            // A bullet glyph, not copy — `verbatim` keeps it out of the catalog.
            Text(verbatim: "·")
                .font(.claim)
                .foregroundStyle(Palette.secondaryText)
                .accessibilityHidden(true)
            Text(text)
                .font(.prose)
                .foregroundStyle(Palette.primaryText)
        }
    }

    // MARK: Disclaimer

    /// The two pages App Store Connect requires and links to from the listing.
    /// Named here so the app and the submission metadata cannot disagree about
    /// where they live.
    /// Computed, not `static let`: the destination follows the language the app
    /// resolved to, so it cannot be fixed at load. `PolicyLinks` owns the mapping and
    /// falls back to the English page rather than guessing a segment.
    static var privacyPolicyURL: URL { PolicyLinks.privacy() }
    static var supportURL: URL { PolicyLinks.support() }

    /// SP-216's passive half. Decision 0029 §2 allows exactly one review route beside
    /// `requestReview`: a link the reader chooses to press, in the one screen they open
    /// deliberately rather than mid-contraction. `?action=write-review` opens the sheet
    /// directly instead of the product page, so the ask is one tap and never a hunt.
    ///
    /// The id is the app record's own (6806088681) and had to wait for it — HD-2 created
    /// the record on 2026-09-05, which is what this line was blocked on since SP-216
    /// shipped its eligibility rules.
    static let appStoreReviewURL = URL(
        string: "https://apps.apple.com/app/id6806088681?action=write-review"
    )!

    private var disclaimer: some View {
        VStack(alignment: .leading, spacing: Metrics.space2) {
            SectionHeader(label: String(localized: "What this app is", comment: "section header above the disclaimer on the Guidance screen"))

            // Both lines come from `Disclaimers` rather than living here as
            // literals: the App Review notes are assembled from the same strings,
            // and a listing that drifts from its app describes a different product.
            Text(Disclaimers.measuredNotDiagnosed)
                .font(.prose)
                .foregroundStyle(Palette.secondaryText)

            // HL-058: no sync, by the ratchet — the iPad's record is the iPad's record,
            // and the honest thing is to say so where the app says what it is.
            if UIDevice.current.userInterfaceIdiom == .pad {
                Text("This iPad keeps its own record. Nothing here is shared with your iPhone or with anyone.", comment: "Guidance screen, iPad only: under the disclaimer, stating that records are not shared between devices")
                    .font(.prose)
                    .foregroundStyle(Palette.secondaryText)
            }

            Text(Disclaimers.onDevice)
                .font(.prose)
                .foregroundStyle(Palette.secondaryText)

            // App Review §5.1.1(i) wants the policy reachable from inside the app,
            // not only from the listing — true even when the honest policy is
            // "nothing is collected". The support link is §1.5's contact route.
            // Three links where there were two, and the row no longer fits by
            // inspection. `ViewThatFits` rather than a `dynamicTypeSize` branch,
            // because type size is not the only thing that overflows it: measured on
            // a 440 pt Max the row is ~365 pt of content, and a 402 pt phone leaves
            // 362 pt between margins — so it is already over at the *default* size on
            // the more common width, before anyone touches accessibility settings.
            // A width test catches both that and AX5; a type-size test catches only
            // one and would have shipped a clipped row to every 402 pt phone.
            //
            // Stacking is the right fallback rather than shrinking: a `Link` that
            // wraps mid-phrase is a tap target whose name breaks in half, and a
            // reader can re-read a broken label but has to hit a broken target.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Metrics.space4) {
                    guidanceLinks
                }
                VStack(alignment: .leading, spacing: Metrics.space3) {
                    guidanceLinks
                }
            }
            .font(.prose)
            .padding(.top, Metrics.space2)

            // The active report route beside the passive links (decision 0029 §3):
            // user-initiated, drafted rather than sent, auditable line by line.
            ReportProblemButton()

            Text("Drafts an email you can read and edit before sending. Your contraction times are never included.", comment: "Guidance screen: caption under the Report a problem button, stating the email is a draft and never carries contraction times")
                .font(.prose)
                .foregroundStyle(Palette.secondaryText)
        }
    }

    /// The three passive routes out of the app, in one place so the stacked and
    /// side-by-side branches above cannot drift apart.
    @ViewBuilder
    private var guidanceLinks: some View {
        Link("Privacy policy", destination: Self.privacyPolicyURL)
        Link("Support", destination: Self.supportURL)
        Link("Rate on the App Store", destination: Self.appStoreReviewURL)
    }
}

#Preview {
    NavigationStack {
        GuidanceScreen()
            .environment(LaborModel())
    }
}
