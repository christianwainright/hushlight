import Foundation
import Testing
@testable import LaborKit

/// Decision 0041's boundaries, plus the pinned copy — the sentence that walks
/// closest to the medical-claims line is the sentence a rewrite must trip a test
/// to touch.
@Suite("Early irregular line")
struct EarlyIrregularTests {
    private func applies(lower: Int, upper: Int, mean: Int) -> Bool {
        EarlyIrregular.applies(
            intervalRange: Duration.seconds(lower)...Duration.seconds(upper),
            averageInterval: .seconds(mean),
            rule: .fiveOneOne
        )
    }

    @Test func theMotivatingExampleFires() {
        // 7:00–12:00 averaging ~9:30 against 5-1-1 — the backlog's own case.
        #expect(applies(lower: 420, upper: 720, mean: 570))
    }

    @Test func wideSpreadAloneDoesNotFire() {
        // Coupling near the threshold: wide, but not slow — 0041 §Rejected. The
        // pattern that deserves closer attention, not a rest note.
        #expect(!applies(lower: 240, upper: 380, mean: 300))
    }

    @Test func slowButEvenDoesNotFire() {
        // Well above the rule but tight spread — a settled slow pattern, not an
        // irregular one; the line's first clause would be false of it.
        #expect(!applies(lower: 540, upper: 600, mean: 570))
    }

    @Test func bothBoundsSitAtExactlyOnePointFive() {
        // ≥ on both, deliberately: at exactly 1.5× the claim "varies" and "well
        // above" are both already honest.
        #expect(applies(lower: 400, upper: 600, mean: 450))
        #expect(!applies(lower: 400, upper: 599, mean: 450))
        #expect(!applies(lower: 400, upper: 600, mean: 449))
    }

    @Test func absentFiguresNeverFire() {
        #expect(!EarlyIrregular.applies(intervalRange: nil, averageInterval: .seconds(600), rule: .fiveOneOne))
        #expect(!EarlyIrregular.applies(
            intervalRange: Duration.seconds(400)...Duration.seconds(700),
            averageInterval: nil, rule: .fiveOneOne
        ))
    }

    /// The copy, pinned verbatim (0041 §3). It observes timing data, licenses rest
    /// as a fact about measurement, and contains no prognosis, no instruction, and
    /// no outcome reassurance — the three ways it goes wrong.
    @Test func theLineIsPinnedVerbatim() {
        #expect(EarlyIrregular.line
            == "Spacing that varies before it settles is how early stretches often look. "
            + "A stretch timed now and then shows the same pattern — this doesn't need "
            + "watching continuously.")
    }

    @Test func theLineSaysNothingTheAppMayNeverSay() {
        let lowered = EarlyIrregular.line.lowercased()
        for banned in Disclaimers.neverSays {
            #expect(!lowered.contains(banned), "line contains banned phrase: \(banned)")
        }
    }
}
