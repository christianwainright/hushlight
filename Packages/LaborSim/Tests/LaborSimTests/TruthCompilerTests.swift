import Foundation
import Testing
@testable import LaborSim

/// The clinical-intent oracle decides what "the app should have said something"
/// means, so its own arithmetic has to be checkable by hand. Every case here is
/// computed on paper in the doc comment above it; if a constant moves, the comment
/// is the thing that shows what it cost.
@Suite("Truth compiler")
struct TruthCompilerTests {

    /// A metronome: `count` contractions every `spacing` seconds, each `duration`
    /// long, starting at `from`. Real physiology never looks like this, which is
    /// exactly why it is the right shape for pinning arithmetic.
    private func metronome(
        count: Int, spacing: Int64, duration: Int64, from: Int64 = 0
    ) -> [TrueContraction] {
        (0..<count).map {
            let start = from + Int64($0) * spacing
            return TrueContraction(start: start, end: start + duration)
        }
    }

    // MARK: Onset

    /// Textbook 5-1-1: every 270 s, 70 s long, from t=0.
    ///
    /// Every dimension except sustainment is satisfied from the first full window:
    /// every in-window interval is 270 s, at or under the 285 s fire margin, so
    /// the frequency share is 100% — comfortably over the two-thirds clause needs;
    /// mean duration 70 ≥ 55 (decision 0023's realigned threshold); the window
    /// holds thirteen contractions against a floor of six; and no gap comes near
    /// the 900 s continuity cap. Sustainment is therefore the binding constraint,
    /// and it clears at exactly `episodeStart + 65 min` = 3900. Hysteresis then
    /// holds the zone shut for another 600 s, so the zone opens at **4500** and
    /// not a second earlier.
    @Test func onsetLandsWhereHandArithmeticSaysItDoes() {
        let stream = metronome(count: 80, spacing: 270, duration: 70)

        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: 3899) == .gray)
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: 3900) == .mustFire)

        let truth = TruthCompiler.compile(trueStream: stream, rules: ["fiveOneOne"])
        let onset = truth.events.first { $0.type == .onsetTrue }
        #expect(onset?.at == 4500)

        let fire = truth.zones.first { $0.kind == .mustFire }
        #expect(fire?.from == 4500)
    }

    /// The same body, judged against a stricter rule. 3-1-1's fire margin is
    /// 165 s (180 − 15) and its not-fire margin is 195 s (180 + 15); every
    /// interval here is 270 s, so 0% of them clear either margin — the frequency
    /// clause condemns outright rather than merely missing the fire share, so the
    /// answer is a clean `mustNotFire` rather than a gray abstention. The app
    /// announcing 3-1-1 here would be a false positive, not a judgement call.
    @Test func aStricterRuleTurnsTheSameLaborIntoAFalsePositiveProbe() {
        let stream = metronome(count: 80, spacing: 270, duration: 70)
        #expect(TruthCompiler.classify(trueStream: stream, rule: "threeOneOne", at: 5000) == .mustNotFire)

        let truth = TruthCompiler.compile(trueStream: stream, rules: ["threeOneOne"])
        #expect(truth.events.contains { $0.type == .neverQualifies && $0.rule == "threeOneOne" })
        #expect(!truth.zones.contains { $0.kind == .mustFire })
    }

    // MARK: The margin band

    /// Exactly at the rule's threshold — every 300 s under 5-1-1 — truth asserts
    /// **nothing**. It is inside neither margin (300 ≰ 285, 300 < 315), so both
    /// firing and staying silent are defensible and the harness must not file a
    /// finding either way. This is the whole reason truth is three-valued: a corpus
    /// that called this instant a pass or a fail would be reporting sampling luck.
    @Test func exactlyAtTheThresholdIsGrayAndAssertsNothing() {
        let stream = metronome(count: 80, spacing: 300, duration: 70)
        for probe: Int64 in [3900, 5000, 9000] {
            #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: probe) == .gray)
        }
        let truth = TruthCompiler.compile(trueStream: stream, rules: ["fiveOneOne"])
        #expect(!truth.zones.contains { $0.kind == .mustFire })
        #expect(truth.events.contains { $0.type == .neverQualifies })
    }

    /// A duration of exactly 50 s meets the boolean's own evidence threshold but
    /// sits dead center of the new duration margin (50 is neither ≥ 55 nor
    /// ≤ 45), so sustainment cannot promote it. (Under the superseded 55/65
    /// pair this duration would have been condemned outright — decision 0023's
    /// amendment moved the margin here specifically so it would not be.)
    @Test func aFiftySecondDurationStaysInsideTheMargin() {
        let stream = metronome(count: 80, spacing: 270, duration: 50)
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: 5000) == .gray)
    }

    /// 40 s is comfortably below the new lower margin (45 s), so silence is
    /// affirmatively correct — the exact both-sides pinning of this boundary is
    /// under "Duration margin" below; this is the same illustrative shape the
    /// frequency test above uses, kept for the margin band as a whole.
    @Test func shortContractionsAreAffirmativelyNotLabor() {
        let stream = metronome(count: 80, spacing: 270, duration: 40)
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: 5000) == .mustNotFire)
    }

    // MARK: Hysteresis

    /// The blip. Truncating the same textbook stream's horizon leaves a raw
    /// `mustFire` run of known length, and the ten-minute dwell decides its fate:
    /// a 200 s brush against the threshold produces no zone at all, while a 700 s
    /// one produces a zone that opens 600 s late. A pattern that touches the rule
    /// for five minutes and retreats is noise in the body, not a labor meeting it.
    @Test func aBriefBrushAgainstTheThresholdOpensNoZone() {
        let stream = metronome(count: 80, spacing: 270, duration: 70)

        let brief = TruthCompiler.compile(trueStream: stream, rules: ["fiveOneOne"], horizon: 4100)
        #expect(!brief.zones.contains { $0.kind == .mustFire })
        #expect(brief.events.contains { $0.type == .neverQualifies })

        let sustained = TruthCompiler.compile(trueStream: stream, rules: ["fiveOneOne"], horizon: 4600)
        #expect(sustained.zones.contains { $0.kind == .mustFire && $0.from == 4500 })
        #expect(sustained.events.contains { $0.type == .onsetTrue && $0.at == 4500 })
    }

    /// A demoted run becomes `gray`, never `mustNotFire`. Truth will not call the
    /// app wrong for noticing something that was genuinely close.
    @Test func aDemotedRunIsGrayNotMustNotFire() {
        let stream = metronome(count: 80, spacing: 270, duration: 70)
        let brief = TruthCompiler.compile(trueStream: stream, rules: ["fiveOneOne"], horizon: 4100)
        let atOnset = brief.zones.first { $0.from <= 3950 && $0.to >= 3950 }
        #expect(atOnset?.kind == .gray)
    }

    // MARK: Evidence floors

    /// Braxton-Hicks: every 25 minutes. The window never holds five, so the answer
    /// is `mustNotFire` at every instant and the scenario is a pure false-positive
    /// probe — any verdict the app renders here is a finding.
    @Test func widelySpacedTighteningsNeverQualifyUnderAnyRule() {
        let stream = metronome(count: 20, spacing: 1500, duration: 40)
        for rule in ["fiveOneOne", "fourOneOne", "threeOneOne"] {
            #expect(TruthCompiler.classify(trueStream: stream, rule: rule, at: 10_000) == .mustNotFire)
            let truth = TruthCompiler.compile(trueStream: stream, rules: [rule])
            #expect(truth.events.contains { $0.type == .neverQualifies && $0.rule == rule })
        }
    }

    /// Before the episode is 55 minutes old nothing can be must-fire, however tight
    /// the spacing — the rule's third term is an hour and truth honours it.
    @Test func theFirstFiftyFiveMinutesAreAffirmativelySilent() {
        let stream = metronome(count: 80, spacing: 150, duration: 80)
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: 3299) == .mustNotFire)
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: 3300) == .gray)
    }

    // MARK: Episodes and staleness

    /// The engine splits episodes on a start-to-start gap *strictly greater* than
    /// two hours, and truth uses the same boundary — this is the pair of instants
    /// the whole `multiDayLatent` gap sweep exists to straddle.
    @Test func exactlyTwoHoursIsOneEpisodeAndOneSecondMoreIsTwo() {
        let joined = [TrueContraction(start: 0, end: 60), TrueContraction(start: 7200, end: 7260)]
        #expect(TruthCompiler.trueEpisodes(joined).count == 1)

        let split = [TrueContraction(start: 0, end: 60), TrueContraction(start: 7201, end: 7261)]
        let episodes = TruthCompiler.trueEpisodes(split)
        #expect(episodes.count == 2)
        #expect(episodes[1].start == 7201)
    }

    @Test func anEpisodeBoundaryIsReportedAsAnEvent() {
        let stream = [TrueContraction(start: 0, end: 60), TrueContraction(start: 7201, end: 7261)]
        let truth = TruthCompiler.compile(trueStream: stream, rules: ["fiveOneOne"])
        let boundaries = truth.events.filter { $0.type == .episodeBoundaryTrue }
        #expect(boundaries.count == 1)
        #expect(boundaries.first?.at == 7201)
    }

    /// Once the body stops, truth goes quiet long before the engine's staleness line.
    ///
    /// This surprised the first draft of this suite and is worth stating plainly:
    /// **at the truth level, staleness is unobservable.** The analysis window is one
    /// hour and the episode-staleness boundary is two, so by the time an episode
    /// could go stale its window has been empty for an hour already and the count
    /// floor has been failing the whole time. Staleness is therefore an *engine
    /// presentation* boundary — whether the readout shows the empty state or keeps
    /// displaying a dead episode's figures — and it belongs to the engine legs, not
    /// here. Phase 3 should probe it there; this oracle cannot see it.
    @Test func truthGoesSilentAnHourAfterTheBodyStopsNotTwo() {
        let stream = metronome(count: 30, spacing: 270, duration: 70)
        let lastStart = stream.last!.start

        // Still inside the window, still plenty of evidence.
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: lastStart + 600) == .mustFire)
        // The window has emptied: the count floor alone decides it.
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: lastStart + 3601) == .mustNotFire)
        // ... and the two-hour staleness line changes nothing that was not already so.
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: lastStart + 7201) == .mustNotFire)
    }

    // MARK: Structure

    /// Zones must tile their horizon without gaps or overlaps: a probe time that
    /// falls into no zone would be an instant the harness silently never judged.
    @Test func zonesTileTheHorizonContiguously() {
        let stream = metronome(count: 80, spacing: 270, duration: 70)
        let truth = TruthCompiler.compile(trueStream: stream, rules: ["fiveOneOne"])
        let zones = truth.zones.sorted { $0.from < $1.from }
        #expect(!zones.isEmpty)
        for (previous, next) in zip(zones, zones.dropFirst()) {
            #expect(previous.to + 1 == next.from)
            // Adjacent zones must differ in *something*, or they should have merged —
            // a redundant split is a zone boundary that means nothing. Kind alone was
            // the whole answer until zones started carrying the clause that condemned
            // them: two neighbouring `mustNotFire` stretches, one for frequency and
            // one for duration, are now a real distinction and the merge deliberately
            // preserves it. Attribution is the point of the field, so the invariant
            // widens rather than the field being flattened back out.
            #expect(previous.kind != next.kind || previous.reason != next.reason)
        }
    }

    /// Compiling two rules at once must not blend them — every zone carries the rule
    /// it belongs to, because the app can be right about one and wrong about another
    /// at the same instant.
    @Test func rulesAreCompiledIndependently() {
        let stream = metronome(count: 80, spacing: 270, duration: 70)
        let truth = TruthCompiler.compile(trueStream: stream, rules: ["fiveOneOne", "threeOneOne"])
        #expect(truth.zones.contains { $0.rule == "fiveOneOne" && $0.kind == .mustFire })
        #expect(!truth.zones.contains { $0.rule == "threeOneOne" && $0.kind == .mustFire })
    }

    @Test func anEmptyStreamNeverQualifies() {
        let truth = TruthCompiler.compile(trueStream: [], rules: ["fiveOneOne"])
        #expect(truth.zones.isEmpty)
        #expect(truth.events.allSatisfy { $0.type == .neverQualifies })
    }

    // MARK: Frequency margin (decision 0024, F-0028) — share, not mean

    /// Six bridging-basis intervals under 5-1-1 (threshold 300, margin 15):
    /// [280, 280, 280, 280, 400, 400]. Four sit at or under 285 — exactly
    /// two-thirds (`4 × 3 = 12 ≥ 6 × 2 = 12`) — so the frequency clause fires.
    /// Duration (70 s), count (6, the floor), sustainment (10 000 s of episode)
    /// and continuity (max gap 400 ≤ 900) all clear too, so the whole `mustFire`
    /// condition holds. `t0` only anchors the episode's start at 0 so
    /// sustainment clears; `p` is the bridging predecessor, outside the window.
    @Test func aFrequencyShareAtExactlyTwoThirdsOfTheFireMarginFires() {
        let stream = [
            TrueContraction(start: 0, end: 70),        // t0: episode anchor
            TrueContraction(start: 6120, end: 6190),    // p: bridges into w0
            TrueContraction(start: 6400, end: 6470),    // w0
            TrueContraction(start: 6680, end: 6750),    // w1 (+280)
            TrueContraction(start: 6960, end: 7030),    // w2 (+280)
            TrueContraction(start: 7240, end: 7310),    // w3 (+280)
            TrueContraction(start: 7640, end: 7710),    // w4 (+400)
            TrueContraction(start: 8040, end: 8110)     // w5 (+400)
        ]
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: 10_000) == .mustFire)
    }

    /// The same shape with one fewer interval under the fire margin —
    /// [285, 285, 285, 300, 300, 300], three of six (`3 × 3 = 9 < 12`) — does
    /// not clear two-thirds. It is also not condemned (all six sit at or under
    /// the 315 s not-fire margin, so the mustNotFire clause reads a 100% share
    /// and stays quiet): the instant is gray, exactly where a share just under
    /// its own boundary belongs.
    @Test func aFrequencyShareJustUnderTwoThirdsOfTheFireMarginDoesNotFire() {
        let stream = [
            TrueContraction(start: 0, end: 70),
            TrueContraction(start: 6115, end: 6185),    // p: bridges into w0 (+285)
            TrueContraction(start: 6400, end: 6470),    // w0
            TrueContraction(start: 6685, end: 6755),    // w1 (+285)
            TrueContraction(start: 6970, end: 7040),    // w2 (+285)
            TrueContraction(start: 7270, end: 7340),    // w3 (+300)
            TrueContraction(start: 7570, end: 7640),    // w4 (+300)
            TrueContraction(start: 7870, end: 7940)     // w5 (+300)
        ]
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: 10_000) == .gray)
    }

    /// Six intervals at [315, 315, 315, 400, 400, 400]: three of six sit at or
    /// under the 315 s not-fire margin — exactly one-half (`3 × 2 = 6 ≤ 6`) —
    /// so the mustNotFire clause condemns. None sit at or under the 285 s fire
    /// margin, so there is no ambiguity with the fire side.
    @Test func aFrequencyShareAtExactlyOneHalfOfTheNotFireMarginIsCondemned() {
        let stream = [
            TrueContraction(start: 0, end: 70),
            TrueContraction(start: 6085, end: 6155),    // p: bridges into w0 (+315)
            TrueContraction(start: 6400, end: 6470),    // w0
            TrueContraction(start: 6715, end: 6785),    // w1 (+315)
            TrueContraction(start: 7030, end: 7100),    // w2 (+315)
            TrueContraction(start: 7430, end: 7500),    // w3 (+400)
            TrueContraction(start: 7830, end: 7900),    // w4 (+400)
            TrueContraction(start: 8230, end: 8300)     // w5 (+400)
        ]
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: 10_000) == .mustNotFire)
    }

    /// One more interval inside the not-fire margin — [315, 315, 315, 315, 400,
    /// 400], four of six (`4 × 2 = 8 > 6`) — clears "at most half" and is not
    /// condemned. Not a fire either (none of the four sit at or under 285), so
    /// the instant is gray: a share that just cleared its own not-fire boundary
    /// is exactly the case truth must not call a false positive.
    @Test func aFrequencyShareJustOverOneHalfOfTheNotFireMarginIsGray() {
        let stream = [
            TrueContraction(start: 0, end: 70),
            TrueContraction(start: 6085, end: 6155),    // p: bridges into w0 (+315)
            TrueContraction(start: 6400, end: 6470),    // w0
            TrueContraction(start: 6715, end: 6785),    // w1 (+315)
            TrueContraction(start: 7030, end: 7100),    // w2 (+315)
            TrueContraction(start: 7345, end: 7415),    // w3 (+315)
            TrueContraction(start: 7745, end: 7815),    // w4 (+400)
            TrueContraction(start: 8145, end: 8215)     // w5 (+400)
        ]
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: 10_000) == .gray)
    }

    // MARK: Duration margin (decision 0023's amendment) — bracketing 50 s, not 60 s

    /// Textbook 5-1-1 spacing (270 s, comfortably inside every other margin)
    /// with duration held at exactly the new fire floor. 55 s ≥ 55 clears it,
    /// so with frequency, count, sustainment and continuity all already true at
    /// this spacing, the instant is `mustFire`.
    @Test func aTrueMeanDurationOfFiftyFiveSecondsIsMustFireEligible() {
        let stream = metronome(count: 80, spacing: 270, duration: 55)
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: 5000) == .mustFire)
    }

    /// One second short of the fire floor and not at or under the not-fire
    /// ceiling either (54 is neither ≥ 55 nor ≤ 45): gray, same shape as the
    /// old 60 s-inside-the-old-margin case this test replaces.
    @Test func aTrueMeanDurationOfFiftyFourSecondsIsNotMustFireEligible() {
        let stream = metronome(count: 80, spacing: 270, duration: 54)
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: 5000) == .gray)
    }

    /// 45 s is at the new not-fire ceiling: this is the exact case decision
    /// 0023's amendment exists to fix. Under the superseded 55/65 margins this
    /// duration (paired with the same spacing) would have sat safely inside the
    /// gray band; against the 50 s evidence threshold the boolean now reads, a
    /// true 45 s pattern is affirmatively not labor.
    @Test func aTrueMeanDurationOfFortyFiveSecondsIsMustNotFire() {
        let stream = metronome(count: 80, spacing: 270, duration: 45)
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: 5000) == .mustNotFire)
    }

    /// One second above the not-fire ceiling: gray, not condemned — the
    /// boundary is exact, same as every other margin in this file.
    @Test func aTrueMeanDurationOfFortySixSecondsIsNotMustNotFire() {
        let stream = metronome(count: 80, spacing: 270, duration: 46)
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: 5000) == .gray)
    }

    // MARK: Sustained continuity (decision 0026) — mustFire only

    /// Seven bridging-basis intervals with one gap held at exactly 3× the 5-1-1
    /// threshold (900 s): [200, 200, 200, 900, 200, 200, 200]. Frequency
    /// (6 of 7 ≤ 285, well over two-thirds), duration (70 s), count (7) and
    /// sustainment (10 100 s) all clear, and continuity holds at the boundary
    /// (900 ≤ 900) — still a sustained pattern.
    @Test func aGapAtExactlyThreeTimesTheThresholdStillSustains() {
        let stream = [
            TrueContraction(start: 0, end: 70),          // t0: episode anchor
            TrueContraction(start: 6300, end: 6370),      // p: bridges into w0
            TrueContraction(start: 6500, end: 6570),      // w0
            TrueContraction(start: 6700, end: 6770),      // w1 (+200)
            TrueContraction(start: 6900, end: 6970),      // w2 (+200)
            TrueContraction(start: 7800, end: 7870),      // w3 (+900, the gap)
            TrueContraction(start: 8000, end: 8070),      // w4 (+200)
            TrueContraction(start: 8200, end: 8270),      // w5 (+200)
            TrueContraction(start: 8400, end: 8470)       // w6 (+200)
        ]
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: 10_100) == .mustFire)
    }

    /// The same shape with the gap widened by one second (901 s, everything
    /// after it shifted to match): continuity breaks, so `mustFire` fails on
    /// that clause alone even though frequency, duration, count and
    /// sustainment are unchanged. It lands in `gray`, not `mustNotFire` — a
    /// broken pattern is a reason to stop demanding a verdict, not a reason to
    /// forbid one (see the file header).
    @Test func aGapOneSecondOverThreeTimesTheThresholdBreaksMustFireToGray() {
        let stream = [
            TrueContraction(start: 0, end: 70),
            TrueContraction(start: 6300, end: 6370),
            TrueContraction(start: 6500, end: 6570),      // w0
            TrueContraction(start: 6700, end: 6770),      // w1 (+200)
            TrueContraction(start: 6900, end: 6970),      // w2 (+200)
            TrueContraction(start: 7801, end: 7871),      // w3 (+901, the gap)
            TrueContraction(start: 8001, end: 8071),      // w4 (+200)
            TrueContraction(start: 8201, end: 8271),      // w5 (+200)
            TrueContraction(start: 8401, end: 8471)       // w6 (+200)
        ]
        #expect(TruthCompiler.classify(trueStream: stream, rule: "fiveOneOne", at: 10_100) == .gray)
    }

    // MARK: Reason attribution (F-0028) — precedence when clauses overlap

    /// A 400 s metronome under 5-1-1 both starves the frequency share (every
    /// interval is 400 s, over the 315 s not-fire margin — a 0% share) and
    /// starves duration (40 s ≤ the 45 s not-fire ceiling) at the same instant.
    /// Count (10 in window) and sustainment (6000 s) are well past their
    /// floors, so the zone at t=6000 is condemned, and precedence
    /// (count → sustained → frequency → duration) means frequency is checked
    /// — and wins — before duration is ever consulted.
    @Test func reasonAttributionFollowsTheDocumentedPrecedenceWhenTwoClausesHold() {
        let stream = metronome(count: 20, spacing: 400, duration: 40)
        let truth = TruthCompiler.compile(trueStream: stream, rules: ["fiveOneOne"])
        let zone = truth.zones.first { $0.from <= 6000 && $0.to >= 6000 }
        #expect(zone?.kind == .mustNotFire)
        #expect(zone?.reason == .frequency)
    }
}
