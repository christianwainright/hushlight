import Foundation
import Testing
@testable import LaborKit

/// The "Report a problem" contract (decision 0029 §3): a mailto the user can
/// audit, carrying versions, device, rule and coarse counts — and structurally
/// unable to carry anything she recorded.
@Suite("Problem report")
struct ProblemReportTests {
    private let context = ProblemReport.Context(
        appVersion: "1.0 (1)",
        osVersion: "iOS 27.0.1",
        deviceModel: "iPhone17,2",
        rule: .fiveOneOne,
        contractionCount: 14,
        episodeCount: 2,
        liveActivityVisible: true,
        storedCrashCount: 1,
        storedHangCount: 0
    )

    @Test func theURLIsAMailtoToTheSupportAddress() throws {
        let url = try #require(ProblemReport.mailtoURL(for: context))
        #expect(url.scheme == "mailto")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.path == ProblemReport.recipient)
        #expect(ProblemReport.recipient == "christian@wainright.net")
    }

    /// Newlines and the interpunct must survive percent-encoding — a body that
    /// arrives as one run-on line is not "readable in the compose window".
    @Test func theBodySurvivesTheURLRoundTripVerbatim() throws {
        let url = try #require(ProblemReport.mailtoURL(for: context))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let body = try #require(components.queryItems?.first(where: { $0.name == "body" })?.value)
        #expect(body == ProblemReport.body(for: context))
        #expect(body.contains("\n"))
    }

    @Test func theBodyCarriesTheCoarseFacts() {
        let body = ProblemReport.body(for: context)
        #expect(body.contains("Hushlight 1.0 (1)"))
        #expect(body.contains("iOS 27.0.1"))
        #expect(body.contains("iPhone17,2"))
        #expect(body.contains("5-1-1"))
        #expect(body.contains("14 contractions across 2 episodes"))
        #expect(body.contains("Live Activity on screen: yes"))
        #expect(body.contains("Crash reports kept on this phone: 1"))
        #expect(body.contains("Hangs: 0"))
    }

    /// The deletability sentence and the marker line are part of the contract, not
    /// decoration: they are what makes the block auditable rather than trusted.
    @Test func theBlockAnnouncesItselfAsDeletable() {
        let body = ProblemReport.body(for: context)
        #expect(body.contains("you can delete any line"))
        #expect(body.contains("Your contraction times are not in this email"))
    }

    @Test("The voice holds: no fear phrases, no exclamation points")
    func voiceRulesHold() {
        let body = ProblemReport.body(for: context) + ProblemReport.subject
        #expect(!body.contains("!"))
        for phrase in Disclaimers.neverSays {
            #expect(!body.lowercased().contains(phrase), "\(phrase)")
        }
    }

    /// Belt and braces on the compile-time guarantee: `Context` has no parameter
    /// that could carry a timestamp, so nothing shaped like a clock time can
    /// appear in the body.
    @Test func nothingShapedLikeAClockTimeAppears() throws {
        let body = ProblemReport.body(for: context)
        #expect(body.ranges(of: /[0-9]{1,2}:[0-9]{2}/).isEmpty)
    }

    @Test func singularCountsReadGrammatically() {
        let single = ProblemReport.Context(
            appVersion: "1.0 (1)",
            osVersion: "iOS 27.0.1",
            deviceModel: "iPhone17,2",
            rule: .fourOneOne,
            contractionCount: 1,
            episodeCount: 1,
            liveActivityVisible: false,
            storedCrashCount: 0,
            storedHangCount: 0
        )
        let body = ProblemReport.body(for: single)
        #expect(body.contains("1 contraction across 1 episode"))
        #expect(!body.contains("1 contractions"))
        #expect(body.contains("Live Activity on screen: no"))
    }
}
