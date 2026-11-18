import Foundation

/// The app's position on what it is, in one place.
///
/// The fitness suite keeps its equivalent in `SharedModels` for the same reason
/// (SP-080): the App Review notes and the copy the app actually shows have to say
/// the same thing, and the cheapest way to guarantee that is for the reviewer's
/// text to be assembled from the same strings the screens render. A listing that
/// drifts from its app is a listing that describes a different product.
public enum Disclaimers {
    /// Rendered on the Guidance screen. Also the App Review position in one line.
    /// A computed property, not a stored constant: `String(localized:)` resolves
    /// against the current locale at call time, the same as every other catalog
    /// lookup in the app.
    public static var measuredNotDiagnosed: String {
        String(
            localized: """
                A stopwatch with arithmetic. It measures contractions and reports the \
                pattern against the guideline you chose. It does not diagnose labor, and \
                it is not medical advice — your provider's instructions always come \
                first. When unsure, call.
                """,
            bundle: .module,
            comment: "the app's single-paragraph statement of what it is and is not, shown on the Guidance screen — also the App Review position, so its wording must stay measured, never diagnostic"
        )
    }

    /// Rendered beneath it. Every clause is a fact about the binary, not a promise.
    public static var onDevice: String {
        String(
            localized: "Everything stays on this phone. No account, no analytics, nothing sent anywhere.",
            bundle: .module,
            comment: "privacy statement shown directly under the disclaimer on the Guidance screen — three factual clauses about the binary, not a promise"
        )
    }

    /// What the app will not say, stated so it can be tested rather than trusted.
    /// Decision 0018 made this the App Review line as well as a voice rule, and
    /// `T0-14` greps rendered text for these.
    ///
    /// English on purpose, for now: HL-008 ("every language carries a per-language
    /// `neverSays` list, so the T0-14 voice grep tests the shipped copy, not the
    /// English original") is what re-cuts this per language. HL-006 catalogs the
    /// copy these phrases are tested *against*; the phrases themselves are the
    /// test's own fixture, not shipped user-facing text.
    // lint-localizable:ignore-start — voice-rule fixture (T0-14), not shipped copy; HL-008 owns the per-language lists
    public static let neverSays = [
        "you are in labor",
        "you're in labor",
        "don't need to go",
        "you must",
        "go to the hospital now",
    ]
    // lint-localizable:ignore-end

    /// Pasted verbatim into App Store Connect's Notes for Review.
    ///
    /// Written against the three guidelines this app is actually judged by: §4.2
    /// (a one-button timer has to earn its place), §1.4.1 (a medical app must
    /// disclose the methodology behind any accuracy claim), and §5.1.3 (health
    /// data and iCloud). Specific rather than generic, because §2.3.1 rejects
    /// generic.
    ///
    /// Deliberately not `String(localized:)`: this text is never rendered inside
    /// the app — it is pasted into App Store Connect's Notes for Review field,
    /// which Apple's reviewers read in English regardless of the build's locale.
    /// `measuredNotDiagnosed` is quoted in *(interpolated below), and that one
    /// clause stays a single source of truth (SP-080) by reading through the real,
    /// localized property — this wrapper paragraph around it stays English-only.
    // lint-localizable:ignore-start — App Store Connect Notes for Review, English-only by definition, never rendered in the app
    public static var reviewNotes: String {
        """
        1. WHAT IT IS AND WHO IT IS FOR
        \(measuredNotDiagnosed)

        For the hours before someone leaves for the hospital: people in late pregnancy \
        and early labour, and the partner holding the phone. A provider says \
        "call when they are five minutes apart, lasting a minute, for an hour" — and at \
        3am there is no knowing whether that has arrived without something doing the \
        arithmetic. Free, nothing to buy, works offline.

        2. ACCESS AND SETUP — NOTHING IS REQUIRED
        No account, login, demo credentials or sample files. Launch it and the button \
        is on the screen. One optional setting: a provider phone number, typed on \
        Guidance, which enables the Call button. A record is two timestamps in the \
        app's local store, visible to no one else, so there is no user-generated \
        content to report or block, and no paid content.

        3. EXTERNAL SERVICES, TOOLS AND PLATFORMS — NONE
        No data provider, authentication, payment, AI, analytics, advertising or \
        crash-reporting service, and no third-party code; every Swift package is local. No networking code — no URLSession, no Network framework, no \
        sockets — and no network entitlement; it behaves identically in airplane mode. \
        Apple frameworks only: SwiftUI, UIKit, SwiftData, ActivityKit, AppIntents, \
        MetricKit, StoreKit, os. MetricKit keeps crash summaries on device, transmitted \
        nowhere; StoreKit is the system rating prompt only, with no In-App Purchase \
        products. Anything that leaves the device does so by her own \
        tap: Call dials the number she typed; Report a problem opens a mail draft she \
        sends or does not; the For the call card's Copy and Share put its summary on \
        the pasteboard or into the system share sheet; the policy links open Safari.

        4. REGIONAL DIFFERENCES — NONE
        Identical in every region: no geo-gating, no regional content, no server. Nine languages change words only; every figure and verdict is computed \
        identically whatever the locale.

        5. REGULATION AND THIRD-PARTY MATERIAL — NEITHER (1.4.1)
        Not a medical device, and it makes no medical claim. Intervals are measured \
        start-to-start, the clinically standard frequency measure; "5-1-1" means \
        contractions about five minutes apart, each about a minute long, sustained for \
        about an hour. It does \
        not diagnose, never says whether the user is in labour, and issues no \
        instruction: when the pattern meets the guideline she selected it reports the \
        measurement and says calling her provider is reasonable. A reference card lists \
        what warrants a call regardless of any timer. \
        No licensed or third-party material: 5-1-1 is widely published guidance and \
        every word is original.

        PRIVACY (5.1.1 / 5.1.3)
        Nothing is collected or transmitted; App Privacy is "Data Not Collected" \
        throughout; no HealthKit, no notifications. The local SwiftData store \
        declares cloudKitDatabase: .none and there is no iCloud entitlement, so data \
        appears only in the user's own device backup. Clear All History deletes \
        everything from inside the app.

        HOW TO TEST — IPHONE OR IPAD
        The app runs on iPhone and iPad and has no Home Screen widget; its one extension \
        renders the Live Activity (on the Lock Screen once "Allow Live Activities from \
        Hushlight?" is accepted) and a Control Center control that starts or ends a \
        contraction, also on the Action button and in Siri. On iPad, History sits \
        beside the timer; on iPhone Duo stood half open, the lower half is the button. Tap the large button \
        at the bottom — Start, then End — and repeat; figures appear as the evidence \
        floors are met. The full verdict needs the guideline's hour; an early verdict \
        ("closer together than the guideline asks") appears after about 20 minutes of \
        minute-long contractions started two minutes apart, as in the screen recording. \
        The For the call card opens from the verdict. Lock the device mid-contraction \
        for the Live Activity.
        """
    }
    // lint-localizable:ignore-end
}
