import Foundation

/// One crash or hang, as MetricKit summarised it: the coarse facts only, never a
/// stack, never anything the user recorded. Kept so that when someone writes in
/// about a problem, "did the app crash for you?" has an answer she can read out.
public struct DiagnosticSummary: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case crash
        case hang
    }

    public let kind: Kind
    /// The end of the payload's reporting window — the day the problem happened,
    /// which is a fact about the app, not a contraction time.
    public let date: Date
    public let appVersion: String
    public let osVersion: String
    /// An exception/signal pair for a crash, a rounded duration for a hang — a
    /// system measurement, never a user figure.
    public let detail: String

    public init(kind: Kind, date: Date, appVersion: String, osVersion: String, detail: String) {
        self.kind = kind
        self.date = date
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.detail = detail
    }
}

/// The last few MetricKit payload summaries, on device and nowhere else
/// (decision 0029 §3). Stored beside the app's other defaults in the same
/// injected-`UserDefaults` idiom as `GuidelineRule` and `ProviderContact`;
/// read by nothing but the problem-report email's coarse counts, transmitted
/// by nothing at all.
public enum DiagnosticArchive {
    /// Named once, for the reason every defaults key here is: the MetricKit
    /// subscriber writes it and the report reads it, and a second copy of the
    /// string is how they stop agreeing.
    public static let defaultsKey = "diagnosticSummaries"

    /// Enough to say "it crashed twice this week"; small enough to stay a
    /// preference rather than become a dataset.
    public static let maxEntries = 5

    /// Prepends, newest first, and drops from the tail past `maxEntries`.
    /// MetricKit delivers on its own queue; `UserDefaults` is thread-safe, so
    /// there is nothing to hop.
    public static func record(_ summary: DiagnosticSummary, in defaults: UserDefaults = .standard) {
        var summaries = Self.summaries(in: defaults)
        summaries.insert(summary, at: 0)
        if summaries.count > maxEntries {
            summaries.removeLast(summaries.count - maxEntries)
        }
        guard let data = try? JSONEncoder().encode(summaries) else { return }
        defaults.set(data, forKey: defaultsKey)
    }

    /// Newest first. Garbage under the key reads as empty rather than throwing —
    /// a diagnostics feature that could itself take the app down would be worse
    /// than none.
    public static func summaries(in defaults: UserDefaults = .standard) -> [DiagnosticSummary] {
        guard let data = defaults.data(forKey: defaultsKey) else { return [] }
        return (try? JSONDecoder().decode([DiagnosticSummary].self, from: data)) ?? []
    }

    /// The two figures a problem report carries — counts, not contents.
    public static func counts(in defaults: UserDefaults = .standard) -> (crashes: Int, hangs: Int) {
        let summaries = Self.summaries(in: defaults)
        return (
            crashes: summaries.count(where: { $0.kind == .crash }),
            hangs: summaries.count(where: { $0.kind == .hang })
        )
    }
}
