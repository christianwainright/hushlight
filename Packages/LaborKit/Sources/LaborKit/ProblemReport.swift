import Foundation

/// The user-initiated "Report a problem" email (decision 0029 §3): the same
/// interaction class as `ProviderContact`'s `tel:` — the OS mail app does the
/// sending, and she sees, edits, or deletes every line before anything goes
/// anywhere. This app never sends an email; it drafts one.
///
/// The composition is pure and takes only the scalars in `Context`, so it cannot
/// see contraction records at all: the compile-time guarantee that no timestamp,
/// duration, or history reaches the body is that no parameter exists to carry one.
/// If a specific bug ever needs her data, we ask in the reply and she decides.
public enum ProblemReport {
    /// Everything a report may carry — versions, device, the chosen rule, and the
    /// coarse shape 0029 §3 enumerates. All plain scalars, gathered by the caller.
    public struct Context: Sendable {
        public let appVersion: String
        public let osVersion: String
        public let deviceModel: String
        public let rule: GuidelineRule
        public let contractionCount: Int
        public let episodeCount: Int
        public let liveActivityVisible: Bool
        public let storedCrashCount: Int
        public let storedHangCount: Int

        public init(
            appVersion: String,
            osVersion: String,
            deviceModel: String,
            rule: GuidelineRule,
            contractionCount: Int,
            episodeCount: Int,
            liveActivityVisible: Bool,
            storedCrashCount: Int,
            storedHangCount: Int
        ) {
            self.appVersion = appVersion
            self.osVersion = osVersion
            self.deviceModel = deviceModel
            self.rule = rule
            self.contractionCount = contractionCount
            self.episodeCount = episodeCount
            self.liveActivityVisible = liveActivityVisible
            self.storedCrashCount = storedCrashCount
            self.storedHangCount = storedHangCount
        }
    }

    /// The address the support page publishes — one destination for both routes.
    public static let recipient = "christian@wainright.net"

    public static var subject: String {
        String(
            localized: "Hushlight problem report",
            bundle: .module,
            comment: "subject line of the Report a problem email the app drafts"
        )
    }

    /// The visible, deletable diagnostic block. Every line is a fact about the app
    /// or the phone; the closing sentence states the one that matters most.
    ///
    /// **HL-007's line, drawn here.** Joining independent, complete lines with a
    /// hard newline is not the fragment-concatenation this item exists to
    /// remove — this is a template email a person reads and edits before
    /// sending, not a sentence, and each line already stands as its own
    /// catalog format string. The actual violation was narrower: the Recorded
    /// line's `contractionNoun`/`episodeNoun` were Swift `== 1` ternaries
    /// choosing between two bare nouns, glued onto their counts by a third,
    /// outer interpolation — English-only agreement no catalog rule backed.
    /// `contractionCountPhrase`/`episodeCountPhrase` below replace them with the
    /// same real-`Int`-through-`variations.plural` shape `LaborFormat.spoken`
    /// and `contractionCount` use elsewhere in this item, each phrase now its
    /// own independently plural-correct catalog entry rather than a number and
    /// a Swift-chosen noun stitched together at the call site.
    /// `locale` defaults to the device's own, same reason and same HL-007 AC as
    /// `CallSummary.callSummary(of:locale:)` — see its doc comment.
    public static func body(for context: Context, locale: Locale = .autoupdatingCurrent) -> String {
        let liveActivityValue = context.liveActivityVisible
            ? String(localized: "yes", bundle: .module, locale: locale, comment: "Report a problem email body: value of the Live Activity on screen line when it is showing")
            : String(localized: "no", bundle: .module, locale: locale, comment: "Report a problem email body: value of the Live Activity on screen line when it is not showing")

        let lines = [
            "",
            String(localized: "Describe what happened above this line.", bundle: .module, locale: locale, comment: "instruction at the top of the Report a problem email's compose window, above the diagnostic block"),
            "",
            String(localized: "— About this app and phone (you can delete any line) —", bundle: .module, locale: locale, comment: "section header inside the Report a problem email body, telling the sender every line below it is editable or deletable"),
            String(localized: "App: Hushlight \(context.appVersion)", bundle: .module, locale: locale, comment: "Report a problem email body line naming the app and its version number"),
            String(localized: "System: \(context.osVersion) · \(context.deviceModel)", bundle: .module, locale: locale, comment: "Report a problem email body line naming the OS version and device model"),
            String(localized: "Guideline: \(context.rule.label)", bundle: .module, locale: locale, comment: "Report a problem email body line naming the contraction guideline currently selected"),
            String(localized: "Recorded: \(contractionCountPhrase(context.contractionCount, locale: locale)) across \(episodeCountPhrase(context.episodeCount, locale: locale))", bundle: .module, locale: locale, comment: "Report a problem email body line giving coarse counts of recorded contractions and episodes — never a timestamp"),
            String(localized: "Live Activity on screen: \(liveActivityValue)", bundle: .module, locale: locale, comment: "Report a problem email body line stating whether the Lock Screen Live Activity is currently showing"),
            String(localized: "Crash reports kept on this phone: \(context.storedCrashCount) · Hangs: \(context.storedHangCount)", bundle: .module, locale: locale, comment: "Report a problem email body line giving coarse counts of stored crash and hang diagnostics"),
            "",
            String(localized: "Your contraction times are not in this email. If a fix needs them, we will ask, and sending them stays your call.", bundle: .module, locale: locale, comment: "closing sentence of the Report a problem email body: states what was deliberately left out, and that sending it later is the sender's own choice"),
        ]
        return "\n" + lines.joined(separator: "\n")
    }

    /// "3 contractions" / "1 contraction" — a real `Int`, interpolated directly,
    /// so it keys into the catalog as `%lld contraction` and resolves through
    /// `variations.plural` rather than a Swift `== 1` ternary choosing the noun.
    private static func contractionCountPhrase(_ count: Int, locale: Locale) -> String {
        String(localized: "\(count) contraction", bundle: .module, locale: locale, comment: "a count of recorded contractions, embedded in the Report a problem email body's Recorded line — catalog plural entry")
    }

    /// "2 episodes" / "1 episode" — same shape as `contractionCountPhrase` above,
    /// for the other count on the same line.
    private static func episodeCountPhrase(_ count: Int, locale: Locale) -> String {
        String(localized: "\(count) episode", bundle: .module, locale: locale, comment: "a count of labor episodes, embedded in the Report a problem email body's Recorded line — catalog plural entry")
    }

    /// `URLComponents` owns the percent-encoding — a hand-encoded newline is how a
    /// mailto body silently loses its line breaks in some mail clients.
    public static func mailtoURL(for context: Context) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body(for: context)),
        ]
        return components.url
    }
}
