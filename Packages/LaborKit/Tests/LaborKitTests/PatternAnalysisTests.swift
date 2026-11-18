import Foundation
import Testing
@testable import LaborKit

/// The analysis is what tells someone it may be time to go to the hospital, so the
/// boundaries are tested on both sides — a verdict that fires early is alarm, one
/// that fires late is worse, and either would be invisible in a happy-path suite.
@Suite("Pattern analysis")
struct PatternAnalysisTests {
    /// Fixed clock; every test builds its own timeline against this.
    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    private func contraction(
        atMinutes minutes: Double,
        lastingSeconds seconds: Double? = 60
    ) -> Contraction {
        let start = base.addingTimeInterval(minutes * 60)
        return Contraction(
            startedAt: start,
            endedAt: seconds.map { start.addingTimeInterval($0) }
        )
    }

    /// Contractions every `spacing` minutes for `count`, each lasting `duration` s.
    private func series(
        count: Int,
        spacingMinutes: Double,
        durationSeconds: Double = 60
    ) -> [Contraction] {
        (0..<count).map {
            contraction(
                atMinutes: Double($0) * spacingMinutes,
                lastingSeconds: durationSeconds
            )
        }
    }

    /// Contractions at named second offsets — for the cases where the point *is* the
    /// spacing between two particular taps and a uniform series cannot express it.
    private func starts(_ offsets: [Double], lastingSeconds seconds: Double = 60) -> [Contraction] {
        offsets.map { offset in
            let start = base.addingTimeInterval(offset)
            return Contraction(startedAt: start, endedAt: start.addingTimeInterval(seconds))
        }
    }

    private func startsAtMinutes(_ minutes: [Double], lastingSeconds seconds: Double = 60) -> [Contraction] {
        starts(minutes.map { $0 * 60 }, lastingSeconds: seconds)
    }

    private func at(seconds: Double) -> Date { base.addingTimeInterval(seconds) }
    private func at(minutes: Double) -> Date { base.addingTimeInterval(minutes * 60) }

    // MARK: Episodes

    @Test func aGapOfExactlyTwoHoursStaysOneEpisode() {
        let contractions = [contraction(atMinutes: 0), contraction(atMinutes: 120)]
        #expect(PatternAnalysis.episodes(contractions).count == 1)
    }

    @Test func aGapOverTwoHoursStartsANewEpisode() {
        let contractions = [
            contraction(atMinutes: 0),
            contraction(atMinutes: 120 + 1.0 / 60.0)
        ]
        let episodes = PatternAnalysis.episodes(contractions)
        #expect(episodes.count == 2)
        #expect(episodes[0].count == 1)
        #expect(episodes[1].count == 1)
    }

    @Test func episodesGroupOnStartToStartGapsRegardlessOfInputOrder() {
        let shuffled = [
            contraction(atMinutes: 130),
            contraction(atMinutes: 0),
            contraction(atMinutes: 5),
            contraction(atMinutes: 135)
        ]
        let episodes = PatternAnalysis.episodes(shuffled)
        #expect(episodes.count == 2)
        #expect(episodes[0].map(\.startedAt) == episodes[0].map(\.startedAt).sorted())
    }

    /// Yesterday's cluster must not feed tonight's readout: an episode whose last
    /// start is more than the gap ago is history, and the pattern is empty.
    @Test func aStaleEpisodeProducesTheEmptyPattern() {
        let contractions = series(count: 8, spacingMinutes: 5)
        let threeHoursAfterLast = base.addingTimeInterval((7 * 5 + 180) * 60)
        let pattern = PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: threeHoursAfterLast
        )
        #expect(pattern == .empty)
    }

    /// **The staleness clock runs on ended contractions only** (decision 0022).
    ///
    /// A contraction still being timed cannot have gone stale, whatever the clock
    /// says: something is happening right now. Without this the readout emptied
    /// underneath its own live count and offered first-launch onboarding copy over a
    /// running 121-minute timer.
    @Test func aRunningContractionKeepsTheEpisodeLivePastTheStaleBoundary() throws {
        var contractions = series(count: 8, spacingMinutes: 5)
        // The newest record opens at +40 min and never closes.
        contractions.append(contraction(atMinutes: 40, lastingSeconds: nil))

        // Two hours and one minute after that start — comfortably past the boundary
        // that empties a finished episode.
        let now = base.addingTimeInterval((40 + 121) * 60)
        let pattern = PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now)

        #expect(pattern != .empty)
        #expect(pattern.running?.startedAt == base.addingTimeInterval(40 * 60))
        #expect(pattern.episode.count == 9)
        #expect(pattern.patternLength == .seconds((40 + 121) * 60))
    }

    /// The exception is exactly that. Close the same record and the boundary bites
    /// at the tick it always did.
    @Test func theStaleBoundaryStillFiresOnceTheRunningRecordCloses() {
        var contractions = series(count: 8, spacingMinutes: 5)
        contractions.append(contraction(atMinutes: 40, lastingSeconds: 60))

        let onTheLine = base.addingTimeInterval(40 * 60 + 7200)
        #expect(PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: onTheLine
        ) != .empty)

        let oneSecondPast = onTheLine.addingTimeInterval(1)
        #expect(PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: oneSecondPast
        ) == .empty)
    }

    // MARK: Negative time

    /// F-0011. `now` can precede the episode's own start after a backward clock set
    /// or a timezone correction. A negative age is not a smaller measurement, it is
    /// an impossible one — and it rendered as "-1 H -10 M".
    @Test func patternLengthFloorsAtZeroWhenTheClockRunsBackwards() throws {
        let contractions = series(count: 4, spacingMinutes: 5)
        // An hour before the episode began.
        let now = base.addingTimeInterval(-3600)
        let pattern = PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now)

        let length = try #require(pattern.patternLength)
        #expect(length == .zero)
        #expect(length >= .zero)
    }

    // MARK: The window count the guidance line speaks from

    @Test func inWindowCountIsTheEvidenceTheAveragesRestOn() {
        // Twelve contractions five minutes apart span 55 minutes; probed 70 minutes
        // in, the oldest three have aged out of the one-hour window.
        let contractions = series(count: 12, spacingMinutes: 5)
        let pattern = PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: base.addingTimeInterval(70 * 60)
        )
        #expect(pattern.episode.count == 12)
        #expect(pattern.inWindowCount == 10)
        #expect(LaborPattern.empty.inWindowCount == 0)
    }

    // MARK: Interval semantics

    /// Frequency is start-to-start. These contractions last 90 s with 5-minute
    /// starts; end-to-start would read 3:30 and wrongly pass a 4-1-1 check.
    @Test func intervalsAreMeasuredStartToStart() throws {
        let contractions = series(count: 4, spacingMinutes: 5, durationSeconds: 90)
        let now = base.addingTimeInterval(16 * 60)
        let pattern = PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now)

        #expect(pattern.averageInterval == .seconds(300))
        #expect(pattern.lastInterval == .seconds(300))

        let fourOneOne = PatternAnalysis.pattern(for: contractions, rule: .fourOneOne, now: now)
        // 5-minute starts fail a 4-minute rule no matter how long each lasts —
        // there just aren't enough of them yet for a verdict at all.
        #expect(fourOneOne.guideline == nil)
    }

    // MARK: Minimum evidence

    @Test func twoContractionsShowNoAverages() {
        let contractions = series(count: 2, spacingMinutes: 5)
        let pattern = PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: base.addingTimeInterval(6 * 60)
        )
        #expect(pattern.averageInterval == nil)
        #expect(pattern.averageDuration == nil)
        #expect(pattern.guideline == nil)
        // The pattern itself is real — it just has no averages worth printing.
        #expect(pattern.episodeStart != nil)
        #expect(pattern.lastInterval == .seconds(300))
    }

    @Test func threeContractionsAreTheFloorForAverages() {
        let contractions = series(count: 3, spacingMinutes: 5)
        let pattern = PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: base.addingTimeInterval(11 * 60)
        )
        #expect(pattern.averageInterval == .seconds(300))
        #expect(pattern.averageDuration == .seconds(60))
    }

    @Test func fiveInWindowIsBelowTheGuidelineEvidenceFloor() {
        let contractions = series(count: 5, spacingMinutes: 5)
        let pattern = PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: base.addingTimeInterval(21 * 60)
        )
        #expect(pattern.averageInterval != nil)
        #expect(pattern.guideline == nil)
    }

    @Test func sixInWindowMeetsTheEvidenceFloor() {
        let contractions = series(count: 6, spacingMinutes: 5)
        let pattern = PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: base.addingTimeInterval(26 * 60)
        )
        #expect(pattern.guideline != nil)
    }

    // MARK: The verdict, dimension by dimension

    /// The canonical send-off: every 5 minutes, a minute long, for over an hour.
    @Test func aTextbookFiveOneOnePatternMeetsTheRule() throws {
        let contractions = series(count: 14, spacingMinutes: 5)
        let now = base.addingTimeInterval((13 * 5 + 1) * 60)
        let pattern = PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now)

        let status = try #require(pattern.guideline)
        #expect(status.frequencyMet)
        #expect(status.durationMet)
        #expect(status.sustainedMet)
        #expect(status.met)
    }

    @Test func sixMinuteSpacingFailsFrequencyOnly() throws {
        let contractions = series(count: 12, spacingMinutes: 6)
        let now = base.addingTimeInterval((11 * 6 + 1) * 60)
        let status = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now).guideline
        )
        #expect(!status.frequencyMet)
        #expect(status.durationMet)
        #expect(status.sustainedMet)
        #expect(!status.met)
    }

    @Test func fortyFiveSecondContractionsFailDurationOnly() throws {
        let contractions = series(count: 14, spacingMinutes: 5, durationSeconds: 45)
        let now = base.addingTimeInterval((13 * 5 + 1) * 60)
        let status = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now).guideline
        )
        #expect(status.frequencyMet)
        #expect(!status.durationMet)
        #expect(!status.met)
    }

    /// A strong pattern that simply hasn't lasted an hour yet — frequency and
    /// duration read as met, sustained does not. This is the state the screen
    /// renders as "keep timing", and it must not trip the banner.
    @Test func aYoungPatternFailsSustainedOnly() throws {
        let contractions = series(count: 8, spacingMinutes: 4)
        let now = base.addingTimeInterval((7 * 4 + 1) * 60)
        let status = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now).guideline
        )
        #expect(status.frequencyMet)
        #expect(status.durationMet)
        #expect(!status.sustainedMet)
        #expect(!status.met)
    }

    // MARK: Boundaries — both sides of every threshold

    @Test func anAverageIntervalExactlyAtThresholdMeetsFrequency() throws {
        // "Every 5 minutes" includes 5:00 exactly; ≤, not <.
        let contractions = series(count: 13, spacingMinutes: 5)
        let now = base.addingTimeInterval((12 * 5 + 1) * 60)
        let status = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now).guideline
        )
        #expect(status.frequencyMet)
    }

    @Test func anAverageIntervalOneSecondOverFailsFrequency() throws {
        let spacing = (5.0 * 60 + 1) / 60  // 5:01 in minutes
        let contractions = series(count: 13, spacingMinutes: spacing)
        let now = base.addingTimeInterval(12 * spacing * 60 + 60)
        let status = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now).guideline
        )
        #expect(!status.frequencyMet)
    }

    /// **Decision 0023.** The duration boundary is the *evidence* threshold, 50 s —
    /// timing starts at the tap, so a recorded average runs behind the felt one by
    /// the thumb's start latency while start-to-start spacing cancels that latency
    /// out. Both sides, one second apart.
    @Test func aFiftySecondAverageMeetsDuration() throws {
        let contractions = series(count: 14, spacingMinutes: 5, durationSeconds: 50)
        let now = base.addingTimeInterval((13 * 5 + 1) * 60)
        let status = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now).guideline
        )
        #expect(status.durationMet)
    }

    @Test func aFortyNineSecondAverageFailsDuration() throws {
        let contractions = series(count: 14, spacingMinutes: 5, durationSeconds: 49)
        let now = base.addingTimeInterval((13 * 5 + 1) * 60)
        let status = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now).guideline
        )
        #expect(!status.durationMet)
    }

    /// The allowance is calibration, not a new rule: the *stated* threshold is still
    /// a minute, and copy quotes it. Two constants exist precisely so neither can be
    /// mistaken for the other, and a 59 s average — which used to fail — now passes
    /// the check while still printing as 0:59.
    @Test func theStatedRuleStaysAMinuteWhileTheCheckAllowsTen() throws {
        #expect(GuidelineRule.fiveOneOne.durationThreshold == .seconds(60))
        #expect(GuidelineRule.fiveOneOne.durationEvidenceThreshold == .seconds(50))

        let contractions = series(count: 14, spacingMinutes: 5, durationSeconds: 59)
        let now = base.addingTimeInterval((13 * 5 + 1) * 60)
        let pattern = PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now)
        #expect(try #require(pattern.guideline).durationMet)
        // And the printed figure is exactly what was recorded — no rounding into
        // the rule's language anywhere.
        #expect(pattern.averageDuration == .seconds(59))
    }

    /// **Decision 0023 §2.** A forgotten stop-tap is evidence a contraction happened,
    /// not a reason to withdraw the whole verdict. With six in the window and a
    /// suspect among them the usable-duration floor relieves from three to two.
    @Test func aSuspectInTheWindowRelievesTheDurationFloorByOne() throws {
        // Six in window; two ordinary contractions and four forgotten stops.
        var contractions = series(count: 6, spacingMinutes: 5)
        for index in 2..<6 {
            let victim = contractions[index]
            contractions[index] = Contraction(
                id: victim.id,
                startedAt: victim.startedAt,
                endedAt: victim.startedAt.addingTimeInterval(200)
            )
        }
        let now = base.addingTimeInterval(26 * 60)
        let pattern = PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now)

        #expect(pattern.inWindowCount == 6)
        #expect(pattern.averageDuration == .seconds(60), "two usable durations clear the relieved floor")
        #expect(pattern.guideline != nil, "one forgotten stop must not null the whole verdict")
    }

    /// The relief stops at two. One usable duration is still one, and an average over
    /// it would be the single-point figure every floor in this file exists to refuse.
    @Test func oneUsableDurationFailsEvenWithASuspectPresent() {
        var contractions = series(count: 6, spacingMinutes: 5)
        for index in 1..<6 {
            let victim = contractions[index]
            contractions[index] = Contraction(
                id: victim.id,
                startedAt: victim.startedAt,
                endedAt: victim.startedAt.addingTimeInterval(200)
            )
        }
        let pattern = PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: base.addingTimeInterval(26 * 60)
        )
        #expect(pattern.inWindowCount == 6)
        #expect(pattern.averageDuration == nil)
        #expect(pattern.guideline == nil)
    }

    /// The other half of the condition: relief is a window rule and needs the window's
    /// own evidence floor behind it. Five in the window, a suspect among them, two
    /// usable durations — the floor stays at three.
    @Test func theSuspectReliefNeedsTheFullWindowEvidenceFloor() {
        var contractions = series(count: 5, spacingMinutes: 5)
        for index in 2..<5 {
            let victim = contractions[index]
            contractions[index] = Contraction(
                id: victim.id,
                startedAt: victim.startedAt,
                endedAt: victim.startedAt.addingTimeInterval(200)
            )
        }
        let pattern = PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: base.addingTimeInterval(21 * 60)
        )
        #expect(pattern.inWindowCount == 5)
        #expect(pattern.averageDuration == nil)
    }

    /// **Decision 0023 §3 — the bridging interval.** The gap into the window's first
    /// contraction is a gap the last hour contains. Two records in the window used to
    /// yield one interval and no average; with the record immediately before them
    /// counted, they yield two and the floor is met one contraction earlier.
    @Test func theIntervalIntoTheWindowCountsAsLastHourEvidence() throws {
        // Starts at 0, 4 and 9 minutes; probed at 62, the window opens at 2 minutes,
        // so only the 4- and 9-minute records are inside it.
        let contractions = startsAtMinutes([0, 4, 9])
        let pattern = PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: at(minutes: 62)
        )

        #expect(pattern.inWindowCount == 2)
        // Both gaps: 0→4 minutes bridges the window edge, 4→9 sits inside it.
        #expect(pattern.averageInterval == .seconds((240 + 300) / 2))
        #expect(pattern.intervalRange == Duration.seconds(240)...Duration.seconds(300))

        // And the taper is exactly one record deep — once the entry record has aged
        // out too, a single in-window contraction is a single contraction again.
        let later = PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: at(minutes: 66)
        )
        #expect(later.inWindowCount == 1)
        #expect(later.averageInterval == nil)
        #expect(later.intervalRange == nil)
    }

    @Test func aPatternFiftyNineMinutesOldFailsSustained() throws {
        // 4-minute spacing, 15 contractions: pattern is 56 minutes old at the last
        // start; probe three minutes later, at 59.
        let contractions = series(count: 15, spacingMinutes: 4)
        let now = base.addingTimeInterval(59 * 60)
        let status = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now).guideline
        )
        #expect(!status.sustainedMet)

        // One minute later the same pattern crosses the hour.
        let later = PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: base.addingTimeInterval(60 * 60)
        )
        #expect(try #require(later.guideline).sustainedMet)
    }

    // MARK: Frequency is a share (decision 0024)

    /// Two thirds exactly passes. Four of six in-window gaps at or under the
    /// threshold is the boundary itself, and it is decided in integers so the case
    /// lands where the rule says rather than where a Double rounds 0.666… to.
    @Test func fourOfSixIntervalsWithinThresholdMeetsFrequency() throws {
        // Gaps: 4, 4, 4, 4, 10, 10 minutes.
        let contractions = startsAtMinutes([0, 4, 8, 12, 16, 26, 36])
        let status = try #require(
            PatternAnalysis.pattern(
                for: contractions, rule: .fiveOneOne, now: at(minutes: 37)
            ).guideline
        )
        #expect(status.frequencyMet)
    }

    /// One gap the other way and the share is a half, which is not most of them.
    @Test func threeOfSixIntervalsWithinThresholdFailsFrequency() throws {
        // Gaps: 4, 4, 4, 10, 10, 10 minutes.
        let contractions = startsAtMinutes([0, 4, 8, 12, 22, 32, 42])
        let status = try #require(
            PatternAnalysis.pattern(
                for: contractions, rule: .fiveOneOne, now: at(minutes: 43)
            ).guideline
        )
        #expect(!status.frequencyMet)
    }

    /// **The case the share exists for (F-0008).** Coupled back labor alternates a
    /// short breath and a long trough; the mean of 2 and 8 minutes is exactly 5:00,
    /// a value that never occurs and that no clinician reads as "every five minutes".
    /// The mean still prints — providers ask for it — and the boolean no longer
    /// rests on it.
    @Test func aCoupledPatternWhoseMeanIsExactlyTheThresholdFailsFrequency() throws {
        // Gaps: 2, 8, 2, 8, 2, 8 minutes. Mean 5:00 on the nose.
        let contractions = startsAtMinutes([0, 2, 10, 12, 20, 22, 30])
        let pattern = PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: at(minutes: 31)
        )

        #expect(pattern.averageInterval == .seconds(300), "the mean is exactly the threshold")
        #expect(!(try #require(pattern.guideline).frequencyMet),
                "half the gaps are eight minutes; that is not a five-minute pattern")
        // And the spread is on screen rather than hidden inside the mean.
        #expect(pattern.intervalRange == Duration.seconds(120)...Duration.seconds(480))
    }

    /// The range is a windowed figure with the same floor as the average it sits
    /// beside: below two intervals there is no spread to report.
    @Test func theIntervalRangeSharesTheAveragesFloor() {
        let pattern = PatternAnalysis.pattern(
            for: series(count: 2, spacingMinutes: 5),
            rule: .fiveOneOne,
            now: base.addingTimeInterval(6 * 60)
        )
        #expect(pattern.averageInterval == nil)
        #expect(pattern.intervalRange == nil)
    }

    @Test func theStricterRulesUseTheirOwnThresholds() throws {
        // Every 3.5 minutes: passes 4-1-1, fails 3-1-1, same data.
        let contractions = series(count: 18, spacingMinutes: 3.5)
        let now = base.addingTimeInterval((17 * 3.5 + 1) * 60)

        let four = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fourOneOne, now: now).guideline
        )
        #expect(four.met)

        let three = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .threeOneOne, now: now).guideline
        )
        #expect(!three.frequencyMet)
    }

    // MARK: Sustained means no gaps (decision 0026)

    /// A long, regular pattern with one deliberate hole in it, probed at the last
    /// start. The lead-in is long enough that the hour is never the thing failing —
    /// only the continuity is under test.
    private func patternWithGap(
        rule: GuidelineRule,
        gapSeconds: Double
    ) -> (contractions: [Contraction], now: Date) {
        let spacing = Double(rule.intervalThreshold.components.seconds)
        var offsets = (0..<20).map { Double($0) * spacing }
        let beforeGap = offsets[offsets.count - 1]
        for index in 0..<6 {
            offsets.append(beforeGap + gapSeconds + Double(index) * spacing)
        }
        return (starts(offsets), at(seconds: offsets[offsets.count - 1]))
    }

    /// Triple the rule's spacing is jitter; one second more is a break. Both sides,
    /// at each of the three rules, because the cap scales with the rule — a
    /// fifteen-minute hole is jitter at 5-1-1 and five missed cycles at 3-1-1.
    @Test(arguments: [GuidelineRule.fiveOneOne, .fourOneOne, .threeOneOne])
    func aGapAtExactlyTripleTheSpacingStillSustains(rule: GuidelineRule) throws {
        let limit = Double(rule.sustainedGapLimit.components.seconds)

        let (within, atProbe) = patternWithGap(rule: rule, gapSeconds: limit - 1)
        let sustained = PatternAnalysis.pattern(for: within, rule: rule, now: atProbe)
        #expect(try #require(sustained.guideline).sustainedMet)
        #expect(sustained.sustainedEvidence == rule.sustainedWindow,
                "an unbroken pattern fills the tape")

        let (over, overProbe) = patternWithGap(rule: rule, gapSeconds: limit + 1)
        let broken = PatternAnalysis.pattern(for: over, rule: rule, now: overProbe)
        #expect(!(try #require(broken.guideline).sustainedMet),
                "a hole one second past the cap is not the same pattern either side of it")
        // The other two dimensions are untouched: five in six gaps are still the
        // rule's spacing, and the contractions are still a minute long. Only
        // continuity failed, and only continuity is reported as failing.
        #expect(try #require(broken.guideline).frequencyMet)
        #expect(try #require(broken.guideline).durationMet)
    }

    /// The tape's own quantity. A break re-anchors it, so it reads the time since
    /// the pattern resumed rather than the time since the episode began — five
    /// contractions of evidence, not an hour and a half of elapsed clock.
    @Test func sustainedEvidenceRestartsAtTheEndOfABreak() {
        let rule = GuidelineRule.fiveOneOne
        let limit = Double(rule.sustainedGapLimit.components.seconds)
        let (contractions, now) = patternWithGap(rule: rule, gapSeconds: limit + 1)
        let pattern = PatternAnalysis.pattern(for: contractions, rule: rule, now: now)

        #expect(pattern.sustainedEvidence == .seconds(5 * 300))
        // While `patternLength` keeps answering its own, different question.
        #expect(pattern.patternLength ?? .zero > rule.sustainedWindow)
    }

    // MARK: The verdict latches (decision 0025, amended)

    /// Durations alternating 60 s and 40 s: as the window slides one contraction at
    /// a time the usable mean crosses 50 s and crosses back, so the raw verdict
    /// flips every five minutes while the body does nothing at all. This is the
    /// F-0009 shape — and every flip used to animate a several-hundred-point verdict
    /// block in above the reader's scroll position and then take it away again.
    private func alternatingDurations() -> [Contraction] {
        (0..<14).map { index in
            let start = base.addingTimeInterval(Double(index) * 300)
            return Contraction(
                id: UUID(),
                startedAt: start,
                endedAt: start.addingTimeInterval(index.isMultiple(of: 2) ? 60 : 40)
            )
        }
    }

    @Test func theRawVerdictFlipsWhileThePresentedOneHolds() throws {
        let contractions = alternatingDurations()

        // Raw true: twelve in window, six of each duration, mean exactly 50.
        let met = PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: at(seconds: 3960)
        )
        #expect(try #require(met.guideline).met)
        #expect(met.presentedMet, "onset is never delayed")

        // Five minutes later the oldest record has aged out, the mean sits at 49.1,
        // and the raw verdict says no — on evidence that changed only by subtraction.
        let flapped = PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: at(seconds: 4260)
        )
        let status = try #require(flapped.guideline, "the verdict must still render to be latched")
        #expect(!status.durationMet)
        #expect(!status.met)
        // `presentedMet` moved to the pattern level (the amendment): it is the same
        // field a floor-drained pattern reads, not a property that only exists
        // beside a rendered `GuidelineStatus`.
        #expect(flapped.presentedMet, "a single tick of contrary evidence cannot retract the verdict")
    }

    /// Release is ten minutes of *continuous* falsehood, and the boundary closes on
    /// the latched side — the direction where the error is one extra second of alarm
    /// rather than one second less of it.
    ///
    /// Asserted through the pure helper rather than through `guideline`: the pattern
    /// this drains has no verdict left to carry the flag by the time it releases,
    /// which is the point — the latch is derived from records and a clock, not held
    /// in a field that has to survive the evidence it was computed from.
    @Test func thePresentedVerdictReleasesAfterTenContinuousMinutes() {
        let contractions = series(count: 14, spacingMinutes: 5)

        // The last instant the raw verdict is true: one second later the sixth
        // contraction leaves the window and the evidence floor is unmet.
        #expect(PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: at(seconds: 6000)
        ).guideline?.met == true)
        #expect(PatternAnalysis.pattern(
            for: contractions, rule: .fiveOneOne, now: at(seconds: 6001)
        ).guideline == nil)

        func presented(_ seconds: Double) -> Bool {
            PatternAnalysis.presentedMet(
                for: contractions, rule: .fiveOneOne, now: at(seconds: seconds)
            )
        }

        #expect(presented(6000), "raw true is presented true, immediately")
        #expect(presented(6000 + 599), "nine minutes fifty-nine seconds: still held")
        #expect(presented(6000 + 600), "exactly ten minutes: still held")
        #expect(!presented(6000 + 601), "ten minutes and one second: released")
    }

    /// The derivation reads the records **as they stood** at each step back. Judging
    /// a past instant with the present record set would let contractions from the
    /// last ten minutes vote in a window they had not joined — and latch onto a
    /// verdict that was never raw-true, which is a false met wearing a latch.
    @Test func theLatchNeverInventsAVerdictFromLaterContractions() {
        // Five contractions an hour ago, then three in the last eight minutes. At
        // 3800 s only four of them were inside the window and no verdict rendered —
        // but hand the same instant the *present* record set and the three newest
        // arrive from the future, clear the evidence floor, and produce one.
        let contractions = starts([0, 300, 600, 900, 1200, 3900, 4000, 4100])
        let past = at(seconds: 3800)

        #expect(PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: past).guideline != nil,
                "the naive reading of a past instant renders a verdict that never existed")
        let asThen = PatternAnalysis.records(contractions, asOf: past)
        #expect(PatternAnalysis.pattern(for: asThen, rule: .fiveOneOne, now: past).guideline == nil,
                "the reconstruction knows those three had not happened yet")

        #expect(!PatternAnalysis.presentedMet(for: contractions, rule: .fiveOneOne, now: at(seconds: 4400)),
                "and so the latch has nothing to hold")

        // The reconstruction's other half: a contraction that had started but not
        // yet ended comes back open, because that is what it was.
        let midContraction = PatternAnalysis.records(contractions, asOf: at(seconds: 4000))
        #expect(midContraction.count == 7)
        #expect(midContraction.last?.endedAt == nil)
    }

    // MARK: The amendment — the latch moves to the pattern level (F-0009's residual)

    /// Seven contractions, five minutes apart: 300 continuous seconds (3600–3900)
    /// where the eighth-oldest-minus-one buffer keeps the window at exactly the
    /// evidence floor, followed by nothing — no new tap ever arrives — so the floor
    /// drains for good once that buffer is spent. Shared by the dip and release
    /// tests below; the recovery test appends a fresh burst of its own.
    private func floorDrainSeries() -> [Contraction] {
        starts([0, 300, 600, 900, 1200, 1500, 1800])
    }

    /// **F-0009's residual, closed.** `presentedMet` used to live on
    /// `GuidelineStatus`, so it could not survive the evidence floor withdrawing
    /// the status entirely — a window that drained below six read `.noVerdict`
    /// instantly, which was 54 of the 69 measured flaps. Moved to the pattern
    /// level, the same held verdict now survives the dip, and reads met again once
    /// fresh evidence clears the floor.
    @Test func dipBelowTheFloorThenRecoveringHoldsPresented() throws {
        let original = floorDrainSeries()

        // Raw met at the hour mark: all seven still sit inside the window.
        let met = PatternAnalysis.pattern(for: original, rule: .fiveOneOne, now: at(seconds: 3600))
        #expect(try #require(met.guideline).met)
        #expect(met.presentedMet)

        // 301 seconds later the second contraction (at 300 s) ages out of the
        // window, dropping the count from six to five — below the floor. The whole
        // `GuidelineStatus` disappears; no dimension flipped, the evidence did.
        let dipped = PatternAnalysis.pattern(for: original, rule: .fiveOneOne, now: at(seconds: 3901))
        #expect(dipped.guideline == nil, "the floor itself withdrew, not a dimension")
        #expect(dipped.presentedMet,
                "a verdict that was raw-true thirty seconds ago must not vanish with the floor")

        // Fresh evidence — a burst bridging in at exactly the continuity limit —
        // clears the floor again well inside the ten-minute release, and the
        // pattern reads genuinely met once more.
        let recovered = original + starts([2700, 3000, 3300, 3600, 3900, 4200])
        let restored = PatternAnalysis.pattern(for: recovered, rule: .fiveOneOne, now: at(seconds: 4260))
        #expect(try #require(restored.guideline).met, "evidence recovered; the pattern is met again")
        #expect(restored.presentedMet)
    }

    /// The floor drain has no recovery this time — nothing new is ever recorded —
    /// so the ten-minute clock the amendment still runs on runs out on schedule.
    /// The last raw-true instant is 3900 (one second before the sixth contraction's
    /// own aging-out); release lands ten minutes and one second after that, the
    /// same closed-boundary rule every latch check in this file uses.
    @Test func aTenMinuteSubFloorRunReleases() {
        let original = floorDrainSeries()

        #expect(PatternAnalysis.presentedMet(for: original, rule: .fiveOneOne, now: at(seconds: 4500)),
                "exactly ten minutes past the last raw-true instant: still held")
        #expect(!PatternAnalysis.presentedMet(for: original, rule: .fiveOneOne, now: at(seconds: 4501)),
                "ten minutes and one second past: released")
    }

    /// **The no-figures guard.** A verdict the latch would otherwise hold — raw-true
    /// within the last ten minutes — must still never present with nothing to show
    /// beside it: "averaging every —, lasting —, for —" is an assertion with no
    /// evidence on screen. Seven contractions a hundred seconds apart give the latch
    /// something genuinely raw-true to find at 3700; by 4150 only the newest
    /// contraction and its single bridging entry remain reachable at all — one
    /// interval short of an average — while the wider pre-check window still holds
    /// every one of the seven, so this is the guard doing the work, not the
    /// pre-check short-circuiting before it.
    @Test func theNoFiguresGuardWithholdsAHeldVerdictWithNoAverageInterval() throws {
        let contractions = starts([0, 100, 200, 300, 400, 500, 600])

        // Setup: raw met at 3700, comfortably inside the ten-minute lookback from
        // 4150 — without the guard the latch would find this and hold.
        let setup = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: at(seconds: 3700)).guideline
        )
        #expect(setup.met)

        let later = PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: at(seconds: 4150))
        #expect(later.averageInterval == nil,
                "setup: only the newest contraction and its single bridging entry remain reachable")
        #expect(!later.presentedMet, "a held verdict must never render with no figures to show beside it")
        #expect(!PatternAnalysis.presentedMet(for: contractions, rule: .fiveOneOne, now: at(seconds: 4150)))
    }

    // MARK: Fast-met (decision 0040)

    /// Eight of six... no — the share exists for exactly this shape (0024's own
    /// case, re-run at half the threshold): four of six gaps at or inside 2:30
    /// (half of 5-1-1's 5:00) is two-thirds, and passes. Everything else is set
    /// comfortably clear of its own floor so only the share is under test: the
    /// pattern runs 22 minutes (past the 20-minute floor), no gap nears the
    /// 15-minute continuity limit, and duration sits at the default 60 s.
    @Test func fourOfSixGapsWithinHalfThresholdMeetsFastFrequency() throws {
        // Gaps: 2, 2, 2, 2, 6, 8 minutes — four at or under 2:30, two well over.
        let contractions = startsAtMinutes([0, 2, 4, 6, 8, 14, 22])
        let status = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: at(minutes: 23)).guideline
        )
        #expect(status.frequencyMet, "setup: the ordinary threshold is not what's under test")
        #expect(status.fastMet)
    }

    /// One gap the other way and the share is a half, same as `frequencyMet`'s own
    /// three-of-six failure — the mirrored machinery fails the mirrored way.
    @Test func threeOfSixGapsWithinHalfThresholdFailsFastFrequency() throws {
        // Gaps: 2, 2, 2, 10, 10, 10 minutes — three at or under 2:30, three well over.
        let contractions = startsAtMinutes([0, 2, 4, 6, 16, 26, 36])
        let status = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: at(minutes: 37)).guideline
        )
        #expect(!status.fastMet)
    }

    /// **Continuity, both sides of the limit** (decision 0026's own clause, reused
    /// rather than restated): triple the rule's spacing — 15 minutes at 5-1-1 — is
    /// jitter; one second more is a break, and a single break anywhere kills
    /// fast-met even though frequency, duration and length all still clear their
    /// own floors comfortably (share 8/9, well past two-thirds).
    private func fastMetContinuityFixture(gapSeconds: Double) -> (contractions: [Contraction], now: Date) {
        var offsets = (0..<9).map { Double($0) * 120 }  // eight 120s gaps, tight
        offsets.append(offsets.last! + gapSeconds)      // the one gap under test
        return (starts(offsets), at(seconds: offsets.last!))
    }

    @Test func aGapAtExactlyTheContinuityLimitStillFastMeets() throws {
        let limit = Double(GuidelineRule.fiveOneOne.sustainedGapLimit.components.seconds)
        let (contractions, now) = fastMetContinuityFixture(gapSeconds: limit)
        let status = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now).guideline
        )
        #expect(status.fastMet)
    }

    @Test func aGapOneSecondOverTheContinuityLimitKillsFastMet() throws {
        let limit = Double(GuidelineRule.fiveOneOne.sustainedGapLimit.components.seconds)
        let (contractions, now) = fastMetContinuityFixture(gapSeconds: limit + 1)
        let status = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now).guideline
        )
        #expect(!status.fastMet, "one break anywhere in the pattern is enough, however good the rest of it is")
    }

    /// **The twenty-minute floor** (`fastMetMinimumLength`, one third of the
    /// sustained window): below it, six-in-window can technically clear while the
    /// whole pattern is a ten-minute flurry. Seven contractions 2:30 apart clear
    /// every other floor at either probe — only `now` moves, so only the pattern's
    /// own age is under test.
    @Test func nineteenMinutesFailsTheFloorTwentyOnePasses() throws {
        let contractions = startsAtMinutes([0, 2.5, 5, 7.5, 10, 12.5, 15])
        #expect(GuidelineRule.fiveOneOne.fastMetMinimumLength == .seconds(20 * 60))

        let young = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: at(minutes: 19)).guideline
        )
        #expect(!young.fastMet, "the pattern itself is fine; it just hasn't run long enough yet")

        let old = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: at(minutes: 21)).guideline
        )
        #expect(old.fastMet)
    }

    /// **`met` outranks `fastMet` the instant the hour completes** — decision
    /// 0040 §1's last clause. Thirty contractions, two minutes apart (comfortably
    /// inside half the threshold, so every other fast-met condition holds for the
    /// whole run): one second before the sustained hour, fast-met carries the
    /// banner; at the hour exactly, the ordinary verdict takes over and fast-met
    /// retires, in the same probe.
    @Test func metOutranksFastMetTheSecondTheHourCompletes() throws {
        let contractions = series(count: 30, spacingMinutes: 2)  // 0…3480s, 120s gaps

        let justBefore = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: at(seconds: 3599)).guideline
        )
        #expect(!justBefore.met)
        #expect(justBefore.fastMet)

        let atTheHour = try #require(
            PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: at(seconds: 3600)).guideline
        )
        #expect(atTheHour.met)
        #expect(!atTheHour.fastMet, "the full verdict outranks it; both are never true together")
    }

    /// **The latch holds through the drop and releases ten minutes later**
    /// (decision 0040 §2, decision 0025's mechanism exactly). Fast-met cannot
    /// wobble on its own dimensions the way the ordinary verdict can — every
    /// non-time condition it adds is strictly stronger than `met`'s own, so
    /// whenever fast-met's other legs hold, `met` is exactly `patternLength >=
    /// the hour`; the only way its raw value drops is the hour completing, tested
    /// above. This test picks up from exactly that drop (the same fixture, the
    /// same last raw-true instant, 3599) and calls `presentedFastMet` directly —
    /// bypassing `pattern(for:rule:now:)`'s own immediate-retirement guard, which
    /// exists precisely for the moment `met` takes over, not for what the bare
    /// latch primitive does — to prove the primitive itself holds for ten full
    /// minutes and releases on the same closed boundary every latch in this file
    /// uses.
    @Test func theFastMetLatchHoldsTenMinutesPastTheLastRawTrueInstantThenReleases() {
        let contractions = series(count: 30, spacingMinutes: 2)  // last raw fast-met instant: 3599s

        func presented(_ seconds: Double) -> Bool {
            PatternAnalysis.presentedFastMet(
                for: contractions, rule: .fiveOneOne, now: at(seconds: seconds)
            )
        }

        #expect(presented(3599), "raw true is presented true, immediately")
        #expect(presented(3599 + 599), "nine minutes fifty-nine seconds past the drop: still held")
        #expect(presented(3599 + 600), "exactly ten minutes past the drop: still held")
        #expect(!presented(3599 + 601), "ten minutes and one second past: released")
    }

    // MARK: Suspect records and the running contraction

    /// A 20-minute "contraction" is a forgotten stop-tap. Its duration would drag
    /// the average over any threshold; its start is still a real tap and still
    /// spaces the intervals.
    @Test func suspectDurationsAreExcludedButTheirStartsStillCount() throws {
        var contractions = series(count: 13, spacingMinutes: 5, durationSeconds: 59)
        // Replace one mid-series record with a forgotten-tap monster.
        let victim = contractions[6]
        contractions[6] = Contraction(
            id: victim.id,
            startedAt: victim.startedAt,
            endedAt: victim.startedAt.addingTimeInterval(20 * 60)
        )
        #expect(contractions[6].isSuspect)

        let now = base.addingTimeInterval((12 * 5 + 1) * 60)
        let pattern = PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now)

        // Twelve 59-second durations, monster excluded: the average stays 59 s and
        // duration honestly fails. With the monster included it would read ~2:34
        // and "pass".
        #expect(pattern.averageDuration == .seconds(59))
        #expect(pattern.averageInterval == .seconds(300))
    }

    /// **The slip, from the other side** (SP-203, decision 0032). An 11-second
    /// "contraction" is a double tap, and it lands in the exact average the
    /// guideline's duration check reads — the long side has always been flagged and
    /// excluded, and the short side was silently trusted.
    @Test func slipsAreExcludedButTheirStartsStillCount() throws {
        var contractions = series(count: 13, spacingMinutes: 5, durationSeconds: 62)
        let victim = contractions[6]
        contractions[6] = Contraction(
            id: victim.id,
            startedAt: victim.startedAt,
            endedAt: victim.startedAt.addingTimeInterval(11)
        )
        #expect(contractions[6].suspicion == .tooShort)

        let now = base.addingTimeInterval((12 * 5 + 1) * 60)
        let pattern = PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now)

        // Twelve 62-second durations, the slip excluded. Included, it would read
        // 58 s here — and with fewer records in the window it crosses the 50 s
        // evidence threshold and takes a true verdict down with it.
        #expect(pattern.averageDuration == .seconds(62))
        #expect(pattern.averageInterval == .seconds(300), "a slip's start is still a tap")
    }

    /// Both bounds admit the believable recording: the rule is *strictly* outside.
    @Test("The suspect bounds are exclusive at both ends", arguments: [
        (19.0, Contraction.Suspicion.tooShort),
        (181.0, Contraction.Suspicion.tooLong),
    ])
    func recordsJustOutsideTheBoundsAreSuspect(_ seconds: Double, _ expected: Contraction.Suspicion) {
        #expect(contraction(atMinutes: 0, lastingSeconds: seconds).suspicion == expected)
    }

    @Test("The bounds themselves are believable", arguments: [20.0, 180.0])
    func recordsExactlyOnTheBoundsAreNotSuspect(_ seconds: Double) {
        #expect(contraction(atMinutes: 0, lastingSeconds: seconds).suspicion == nil)
    }

    /// **Only the long side relieves the duration floor** (decision 0032). A
    /// forgotten stop-tap is evidence a contraction happened and ran long; a slip is
    /// evidence of nothing, and must not lower the bar for the verdict it is noise in.
    @Test func aSlipDoesNotRelieveTheDurationFloorTheWayAForgottenStopDoes() throws {
        // Six starts clear the guideline floor. Three of them never got an end tap
        // at all, so only two believable durations remain — one under the ordinary
        // floor of three, which means the mean exists only if the relief applies.
        func window(with mistake: Double) -> [Contraction] {
            (0..<6).map { index in
                let start = base.addingTimeInterval(Double(index) * 5 * 60)
                let length: Double? = switch index {
                case 0, 1, 2: nil            // no end tap — nothing to average
                case 5: mistake              // the record under test
                default: 62                  // believable
                }
                return Contraction(
                    startedAt: start,
                    endedAt: length.map { start.addingTimeInterval($0) }
                )
            }
        }

        let withForgottenStop = PatternAnalysis.pattern(
            for: window(with: 20 * 60), rule: .fiveOneOne, now: base.addingTimeInterval(26 * 60)
        )
        let withSlip = PatternAnalysis.pattern(
            for: window(with: 11), rule: .fiveOneOne, now: base.addingTimeInterval(26 * 60)
        )

        #expect(withForgottenStop.averageDuration == .seconds(62),
                "a forgotten stop relieves the floor by one — its own evidence must not null the verdict")
        #expect(withSlip.averageDuration == nil,
                "a slip is evidence of nothing and must not relieve the same floor")
    }

    /// History's own averages read the same rule; a slip must not flatter the line a
    /// provider gets shown either.
    @Test func theEpisodeSummaryExcludesSlipsToo() throws {
        var contractions = series(count: 6, spacingMinutes: 5, durationSeconds: 62)
        let victim = contractions[2]
        contractions[2] = Contraction(
            id: victim.id,
            startedAt: victim.startedAt,
            endedAt: victim.startedAt.addingTimeInterval(4)
        )
        let summary = try #require(PatternAnalysis.summary(of: contractions))
        #expect(summary.averageDuration == .seconds(62))
        #expect(summary.count == 6, "the record is still in the history, only out of the mean")
    }

    // MARK: The forgotten timer, while it is still running (SP-204)

    /// `suspicion` needs `endedAt`, so the CHECK flag structurally could not fire on
    /// the one record actually on screen. `isRunningLong` is the live form of the
    /// same judgement, at the same bound.
    @Test func aRunningRecordReadsAsLongOnlyPastTheSuspectBound() {
        let start = base
        let running = Contraction(startedAt: start)

        #expect(!running.isRunningLong(at: start.addingTimeInterval(179)))
        #expect(!running.isRunningLong(at: start.addingTimeInterval(180)), "the bound itself is still a contraction")
        #expect(running.isRunningLong(at: start.addingTimeInterval(181)))
        #expect(running.suspicion == nil, "nothing has been recorded yet to be suspicious of")
    }

    /// A record that ended is judged by `suspicion`, never by this — otherwise a
    /// finished 20-minute record would report both, and the two could disagree.
    @Test func aFinishedRecordIsNeverRunningLongHoweverLongItRan() {
        let start = base
        let finished = Contraction(startedAt: start, endedAt: start.addingTimeInterval(20 * 60))

        #expect(!finished.isRunningLong(at: start.addingTimeInterval(30 * 60)))
        #expect(finished.suspicion == .tooLong, "the ended form of the same fact")
    }

    /// The clock can go backwards; the answer must not become "yes" by arithmetic.
    @Test func aBackwardClockNeverMakesARunningRecordLong() {
        let start = base
        let running = Contraction(startedAt: start)
        #expect(!running.isRunningLong(at: start.addingTimeInterval(-3600)))
    }

    @Test func aRunningContractionIsSurfacedAndExcludedFromDurations() throws {
        var contractions = series(count: 6, spacingMinutes: 5)
        contractions.append(contraction(atMinutes: 30, lastingSeconds: nil))

        let now = base.addingTimeInterval(30.5 * 60)
        let pattern = PatternAnalysis.pattern(for: contractions, rule: .fiveOneOne, now: now)

        #expect(pattern.running?.startedAt == base.addingTimeInterval(30 * 60))
        // Six completed 60 s durations; the running one contributes nothing yet.
        #expect(pattern.averageDuration == .seconds(60))
    }

    @Test func theEmptyInputProducesTheEmptyPattern() {
        #expect(PatternAnalysis.pattern(for: [], rule: .fiveOneOne, now: base) == .empty)
    }
}
