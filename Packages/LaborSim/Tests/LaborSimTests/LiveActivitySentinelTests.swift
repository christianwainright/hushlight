#if os(iOS)
import Foundation
import Testing
import LaborKit

/// Rubric T2-08 / weakness W9, in both halves.
///
/// `StartStopContractionIntent` used to hard-code `rule: .fiveOneOne` when it
/// recomputed the pattern for the lock screen, while the in-app rule is
/// user-selectable (F-0013). That divergence was latent only because `ContentState`
/// never renders a verdict — just the running flag and the raw count/interval figures
/// a picker choice cannot contradict. It is reconciled now: both surfaces read one
/// persisted key, and the first test below is what keeps that true.
///
/// The second is a shape sentinel rather than a behaviour test. The day `ContentState`
/// grows a verdict-shaped field (a `met` bool, a `guideline` summary, anything derived
/// from `GuidelineRule`), the lock screen becomes a surface that can contradict the
/// app — and one the user cannot correct from. This exists to fail the moment such a
/// field is added, so that change gets a deliberate answer rather than shipping as a
/// drive-by.
@Suite("Live Activity divergence sentinel")
struct LiveActivitySentinelTests {

    /// One key, read by the intent and written by the model. A second copy of this
    /// string is how the two surfaces would part company again.
    @Test func theIntentAndTheAppResolveTheRuleThroughOneKey() throws {
        let suite = "net.wainright.laborsim.sentinel-rule"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        #expect(GuidelineRule.defaultsKey == "guidelineRule")
        #expect(GuidelineRule.persisted(in: defaults) == .fiveOneOne,
                "the taught default stands when nothing is stored")

        for rule in GuidelineRule.allCases {
            defaults.set(rule.rawValue, forKey: GuidelineRule.defaultsKey)
            #expect(GuidelineRule.persisted(in: defaults) == rule)
        }

        defaults.set("notARule", forKey: GuidelineRule.defaultsKey)
        #expect(GuidelineRule.persisted(in: defaults) == .fiveOneOne,
                "an unreadable stored value falls back rather than trapping mid-labor")
    }

    @Test func contentStateCarriesExactlyTheseFourFields() {
        // Four, since SP-213 (2026-08-24): `averageIntervalSeconds` joined so the
        // idle lock screen can lead with the average instead of one pair's outlier
        // gap. This sentinel tripped on the addition, exactly as intended — the
        // Live Activity contract does not grow by accident, and this comment is
        // the deliberate act the trip demands.
        let state = ContractionActivityAttributes.ContentState(
            runningSince: Date(timeIntervalSince1970: 1_800_000_000),
            averageIntervalSeconds: 310,
            lastIntervalSeconds: 300,
            contractionCount: 4
        )

        let labels = Mirror(reflecting: state).children.compactMap(\.label)
        let expected: Set<String> = [
            "runningSince", "averageIntervalSeconds", "lastIntervalSeconds", "contractionCount",
        ]

        #expect(
            labels.count == expected.count,
            "ContentState has \(labels.count) fields, expected \(expected.count): \(labels)"
        )
        #expect(
            Set(labels) == expected,
            "ContentState fields changed shape — got \(Set(labels)), expected \(expected)"
        )
    }
}
#endif
