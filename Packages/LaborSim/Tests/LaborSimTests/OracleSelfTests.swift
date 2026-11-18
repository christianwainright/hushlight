import Testing
import LaborOracle

/// Fixed epoch for every test in this file: an arbitrary but stable second count so
/// expectations never depend on wall-clock time.
let t0: Int64 = 1_800_000_000

/// Builds a completed contraction: `createdBy`, a start offset from `t0`, and a
/// duration.
private func rec(_ createdBy: Int, startOffset: Int64, duration: Int64) -> OracleRecord {
    OracleRecord(createdBy: createdBy, start: t0 + startOffset, end: t0 + startOffset + duration)
}

@Suite("Oracle math")
struct OracleSelfTests {

    /// Six contractions 300s apart, 60s each, judged 60s after the last start. Pins:
    /// the evidence floor is met (6 in-window), the mean arithmetic is exact
    /// (1500/5 = 300, 360/6 = 60), frequencyMet (a 100% share, decision 0024) and
    /// durationMet (60s clears the 50s evidence threshold, decision 0023) both pass,
    /// but the episode is only 1560s old so sustainedMet — and therefore
    /// guidelineMet — is false. This is the "two legs out of three" boundary.
    @Test("Six contractions 300s apart, 60s each: frequency and duration met, not yet sustained")
    func sixContractionsNotYetSustained() {
        let records = (0..<6).map { i in rec(i, startOffset: Int64(i) * 300, duration: 60) }
        let now = t0 + 1500 + 60
        let result = OracleMath.pattern(records: records, rule: .fiveOneOne, now: now)

        #expect(result.inWindowCount == 6)
        #expect(result.averageInterval?.sumSeconds == 1500)
        #expect(result.averageInterval?.count == 5)
        #expect(result.averageInterval?.value == 300)
        #expect(result.averageDuration?.sumSeconds == 360)
        #expect(result.averageDuration?.count == 6)
        #expect(result.averageDuration?.value == 60)
        #expect(result.frequencyMet == true)
        #expect(result.durationMet == true)
        #expect(result.sustainedMet == false)
        #expect(result.guidelineMet == false)
    }

    /// Same shape as above but 13 contractions, so the episode spans 3660s by the
    /// time it's judged — past the one-hour sustained threshold. Pins that once all
    /// three legs pass, guidelineMet flips true, and that the rolling window
    /// correctly drops the earliest contraction (now - 3600 excludes offset 0).
    @Test("13 contractions 300s apart spanning 3660s: sustained pattern renders guidelineMet true")
    func sustainedPatternMeetsGuideline() {
        let records = (0..<13).map { i in rec(i, startOffset: Int64(i) * 300, duration: 60) }
        let now = t0 + 3600 + 60
        let result = OracleMath.pattern(records: records, rule: .fiveOneOne, now: now)

        #expect(result.inWindowCount == 12) // offset-0 start falls just outside the window
        #expect(result.averageInterval?.value == 300)
        #expect(result.averageDuration?.value == 60)
        #expect(result.sustainedMet == true)
        #expect(result.guidelineMet == true)
    }

    /// Both sides of the fiveOneOne interval threshold (300s), now the per-interval
    /// boundary feeding the frequency **share** (decision 0024) rather than a bare
    /// mean: with every gap identical, the share is all-or-nothing, so this still
    /// pins the same closed (<=) boundary the old mean-based test did. The
    /// share-specific boundary (some gaps in, some out) is
    /// `frequencyShareFourOfSixPassesThreeOfSixFails` below.
    @Test("Average interval exactly at the fiveOneOne threshold (300s) meets frequency; 301s misses it")
    func frequencyThresholdBothSides() {
        func makeResult(interval: Int64) -> OraclePattern {
            let records = (0..<6).map { i in rec(i, startOffset: Int64(i) * interval, duration: 60) }
            let now = t0 + interval * 5 + 60
            return OracleMath.pattern(records: records, rule: .fiveOneOne, now: now)
        }

        #expect(makeResult(interval: 300).frequencyMet == true)
        #expect(makeResult(interval: 301).frequencyMet == false)
    }

    /// The frequency boundary is a share (decision 0024): at least two-thirds of
    /// in-window intervals must sit at or under the rule's threshold. Four of six is
    /// the exact boundary (4*3 == 6*2, decided in integers) and passes; three of six
    /// sits under it and fails.
    @Test("Frequency share: four-of-six in-window intervals within threshold passes (exactly 2/3); three-of-six fails")
    func frequencyShareFourOfSixPassesThreeOfSixFails() {
        func makeResult(gaps: [Int64]) -> OraclePattern {
            var offset: Int64 = 0
            var records: [OracleRecord] = [rec(0, startOffset: 0, duration: 70)]
            for (index, gap) in gaps.enumerated() {
                offset += gap
                records.append(rec(index + 1, startOffset: offset, duration: 70))
            }
            let now = t0 + offset + 60
            return OracleMath.pattern(records: records, rule: .fiveOneOne, now: now)
        }

        let fourOfSix = makeResult(gaps: [100, 100, 100, 100, 400, 400])
        #expect(fourOfSix.inWindowCount == 7)
        #expect(fourOfSix.frequencyMet == true)

        let threeOfSix = makeResult(gaps: [100, 100, 100, 400, 400, 400])
        #expect(threeOfSix.inWindowCount == 7)
        #expect(threeOfSix.frequencyMet == false)
    }

    /// The coupling shape decision 0024 exists for (F-0008, F-0012): alternating
    /// short and long gaps whose *mean* sits exactly on the threshold. Averaging
    /// 120s and 480s says "every five minutes"; only half the individual gaps
    /// actually are. The old mean-based boolean passed this outright; the share
    /// fails it, because only 3 of 6 gaps (50%) are individually within threshold.
    @Test("Alternating 120s/480s gaps average exactly 300s but the share is 50%, under two-thirds: frequencyMet is false")
    func frequencyMeanAtThresholdButShareFails() {
        let gaps: [Int64] = [120, 480, 120, 480, 120, 480]
        var offset: Int64 = 0
        var records: [OracleRecord] = [rec(0, startOffset: 0, duration: 70)]
        for (index, gap) in gaps.enumerated() {
            offset += gap
            records.append(rec(index + 1, startOffset: offset, duration: 70))
        }
        let now = t0 + offset + 60
        let result = OracleMath.pattern(records: records, rule: .fiveOneOne, now: now)

        #expect(result.averageInterval?.value == 300)
        #expect(result.frequencyMet == false)
    }

    /// Both sides of the duration **evidence** threshold (50s, decision 0023): 50
    /// meets it, 49 misses it. The stated rule (60s, `durationThresholdSeconds`)
    /// is unchanged and is pinned separately below so copy and boolean cannot
    /// collapse into the same number.
    @Test("Average duration exactly 50s meets the duration leg (decision 0023's evidence threshold); 49s misses it")
    func durationEvidenceThresholdBothSides() {
        func makeResult(duration: Int64) -> OraclePattern {
            let records = (0..<6).map { i in rec(i, startOffset: Int64(i) * 300, duration: duration) }
            let now = t0 + 300 * 5 + duration
            return OracleMath.pattern(records: records, rule: .fiveOneOne, now: now)
        }

        #expect(makeResult(duration: 50).durationMet == true)
        #expect(makeResult(duration: 49).durationMet == false)
    }

    /// The rule as stated (60s, what copy quotes) and the rule as measured (50s,
    /// decision 0023) are deliberately different numbers on every rule variant, so
    /// nobody can collapse them into one.
    @Test("The stated duration rule (60s) and the evidence threshold (50s) never collapse into the same number")
    func durationStatedThresholdStaysSixtyWhileEvidenceThresholdIsFifty() {
        for rule in OracleRule.allCases {
            #expect(rule.durationThresholdSeconds == 60)
            #expect(rule.durationEvidenceThresholdSeconds == 50)
        }
    }

    /// The duration floor relief (decision 0023 §2): with >=6 in-window records and
    /// at least one suspect present, the usable-duration floor drops from three to
    /// two. Two usable durations clear the relieved floor; the same two do not
    /// clear the un-relieved floor of three at only five in-window.
    @Test("Duration floor relief: >=6 in-window with a suspect drops the usable-duration floor from 3 to 2")
    func durationFloorReliefWithSixInWindowAndASuspect() {
        let records = [
            rec(0, startOffset: 0, duration: 70),
            rec(1, startOffset: 300, duration: 70),
            rec(2, startOffset: 600, duration: 200), // suspect: over 180
            rec(3, startOffset: 900, duration: 200),
            rec(4, startOffset: 1200, duration: 200),
            rec(5, startOffset: 1500, duration: 200),
        ]
        let now = t0 + 1500 + 60
        let result = OracleMath.pattern(records: records, rule: .fiveOneOne, now: now)

        #expect(result.inWindowCount == 6)
        #expect(result.averageDuration?.count == 2, "two usable durations should clear the relieved floor")
        #expect(result.averageDuration?.value == 70)
        #expect(result.durationMet == true)

        // Without the relief (only five in window, still one suspect), the same two
        // usable durations do not clear the un-relieved floor of three.
        let fiveInWindow = Array(records.dropLast())
        let fiveNow = t0 + 1200 + 60
        let fiveResult = OracleMath.pattern(records: fiveInWindow, rule: .fiveOneOne, now: fiveNow)
        #expect(fiveResult.inWindowCount == 5)
        #expect(fiveResult.averageDuration == nil, "without the floor relief, two usable durations should not clear it")
    }

    /// Five in-window contractions render no verdict at all — not even a false one —
    /// because the evidence floor is 6. A sixth turns the verdict on. Pins that the
    /// floor gates the whole verdict, not just individual legs.
    @Test("Evidence floor: five in-window contractions render no verdict; a sixth turns it on")
    func evidenceFloorOfSix() {
        let fiveRecords = (0..<5).map { i in rec(i, startOffset: Int64(i) * 300, duration: 60) }
        let nowFive = t0 + 4 * 300 + 60
        let fiveResult = OracleMath.pattern(records: fiveRecords, rule: .fiveOneOne, now: nowFive)

        #expect(fiveResult.inWindowCount == 5)
        #expect(fiveResult.frequencyMet == nil)
        #expect(fiveResult.durationMet == nil)
        #expect(fiveResult.sustainedMet == nil)
        #expect(fiveResult.guidelineMet == nil)

        let sixRecords = (0..<6).map { i in rec(i, startOffset: Int64(i) * 300, duration: 60) }
        let nowSix = t0 + 5 * 300 + 60
        let sixResult = OracleMath.pattern(records: sixRecords, rule: .fiveOneOne, now: nowSix)

        #expect(sixResult.inWindowCount == 6)
        #expect(sixResult.frequencyMet != nil)
    }

    /// Exactly two in-window records give exactly one interval, which is below the
    /// floor of two intervals (three records) — no pre-window record exists here to
    /// bridge from (decision 0023 §3), so there is nothing to raise it to two.
    /// Pins averageInterval's own floor, separate from the six-record verdict floor
    /// above, and intervalMinSeconds/intervalMaxSeconds (decision 0024 §2) share
    /// the same floor.
    @Test("Two in-window records give one interval, below the floor of two: averageInterval and interval range are nil")
    func averageIntervalFloorOfTwoIntervals() {
        let records = [rec(0, startOffset: 0, duration: 60), rec(1, startOffset: 300, duration: 60)]
        let now = t0 + 300 + 60
        let result = OracleMath.pattern(records: records, rule: .fiveOneOne, now: now)

        #expect(result.inWindowCount == 2)
        #expect(result.averageInterval == nil)
        #expect(result.intervalMinSeconds == nil)
        #expect(result.intervalMaxSeconds == nil)
    }

    /// intervalMinSeconds/intervalMaxSeconds (decision 0024 §2) are the in-window
    /// spread — a raw fact alongside the mean that makes bimodality visible. Present
    /// with the true min/max as soon as the two-interval floor is met.
    @Test("Interval range: present with the true min/max once the two-interval floor is met")
    func intervalRangePresentAboveTheFloor() {
        let records = [
            rec(0, startOffset: 0, duration: 60),
            rec(1, startOffset: 100, duration: 60),
            rec(2, startOffset: 600, duration: 60),
            rec(3, startOffset: 900, duration: 60),
        ]
        let now = t0 + 900 + 60
        let result = OracleMath.pattern(records: records, rule: .fiveOneOne, now: now)

        // Gaps: 100, 500, 300 — mean 300, min 100, max 500.
        #expect(result.inWindowCount == 4)
        #expect(result.intervalMinSeconds == 100)
        #expect(result.intervalMaxSeconds == 500)
        #expect(result.averageInterval?.value == 300)
    }

    /// A 181s contraction is suspect (strictly over 180) and is dropped from the
    /// duration mean, but its start still contributes to averageInterval — interval
    /// math never looks at duration at all. A 180s contraction sits exactly on the
    /// usable side of the line. Counts are asserted explicitly so the exclusion is
    /// visible as arithmetic, not just a shifted average.
    @Test("Suspect duration (181s) excluded from duration mean but its start still counts for intervals; 180s is included")
    func suspectDurationExclusion() {
        let records = [
            rec(0, startOffset: 0, duration: 60),
            rec(1, startOffset: 300, duration: 60),
            rec(2, startOffset: 600, duration: 181), // suspect: strictly over 180
            rec(3, startOffset: 900, duration: 60),
        ]
        let now = t0 + 900 + 60
        let result = OracleMath.pattern(records: records, rule: .fiveOneOne, now: now)

        #expect(result.inWindowCount == 4)
        // All four starts count toward intervals regardless of the suspect duration.
        #expect(result.averageInterval?.count == 3)
        #expect(result.averageInterval?.sumSeconds == 900)
        // Only 3 of the 4 durations are usable — the 181s one is dropped.
        #expect(result.averageDuration?.count == 3)
        #expect(result.averageDuration?.sumSeconds == 180)

        let boundaryRecords = [
            rec(0, startOffset: 0, duration: 60),
            rec(1, startOffset: 300, duration: 60),
            rec(2, startOffset: 600, duration: 180), // exactly usable, not suspect
            rec(3, startOffset: 900, duration: 60),
        ]
        let boundaryResult = OracleMath.pattern(records: boundaryRecords, rule: .fiveOneOne, now: now)
        #expect(boundaryResult.averageDuration?.count == 4)
        #expect(boundaryResult.averageDuration?.sumSeconds == 360)
    }

    /// Episode split boundary: a 7200s gap stays one episode; 7201s splits into two.
    /// When split, `pattern` must report only the later episode.
    @Test("Episode split: 7200s gap stays one episode, 7201s splits into two and pattern reports the later one")
    func episodeSplitBoundary() {
        let staying = [rec(0, startOffset: 0, duration: 60), rec(1, startOffset: 7200, duration: 60)]
        #expect(OracleMath.episodes(staying).count == 1)

        let splitting = [rec(0, startOffset: 0, duration: 60), rec(1, startOffset: 7201, duration: 60)]
        #expect(OracleMath.episodes(splitting).count == 2)

        let now = t0 + 7201 + 60
        let result = OracleMath.pattern(records: splitting, rule: .fiveOneOne, now: now)
        #expect(result.episode.count == 1)
        #expect(result.episode.first?.createdBy == 1)
    }

    /// Staleness boundary: last start exactly 7200s before now is still a live
    /// pattern; one second later (7201s) it's the empty state.
    @Test("Staleness: last start 7200s before now is still live; 7201s before now is the empty state")
    func stalenessBoundary() {
        let records = [rec(0, startOffset: 0, duration: 60)]

        let stillLive = OracleMath.pattern(records: records, rule: .fiveOneOne, now: t0 + 7200)
        #expect(stillLive.hasPattern == true)

        let stale = OracleMath.pattern(records: records, rule: .fiveOneOne, now: t0 + 7201)
        #expect(stale.hasPattern == false)
    }

    /// Window edge: a contraction starting exactly at now - 3600 is in-window; one
    /// second earlier (now - 3601) it is not, and its interval to the next
    /// contraction is not counted at all — not clamped, just absent.
    @Test("Window edge: a start exactly at now-3600 is in-window; now-3601 is not, and its interval is excluded")
    func windowEdgeBoundary() {
        let now = t0 + 10_000

        let inRecords = [
            rec(0, startOffset: 6400, duration: 60),  // start == now - 3600, inclusive edge
            rec(1, startOffset: 6700, duration: 60),
        ]
        let inResult = OracleMath.pattern(records: inRecords, rule: .fiveOneOne, now: now)
        #expect(inResult.inWindowCount == 2)

        let outRecords = [
            rec(0, startOffset: 6399, duration: 60),  // start == now - 3601, just outside
            rec(1, startOffset: 6699, duration: 60),
        ]
        let outResult = OracleMath.pattern(records: outRecords, rule: .fiveOneOne, now: now)
        #expect(outResult.inWindowCount == 1)
        // The out-of-window record bridges in as the entry (decision 0023 §3), so
        // there is one interval here now, not zero — but one interval is still below
        // the two-interval floor, so averageInterval stays nil for the same reason
        // as always: not enough evidence, not "nothing to compute".
        #expect(outResult.averageInterval == nil)
    }

    /// Sustained needs continuity, not just elapsed time (decision 0026): the hour
    /// can be satisfied while an in-window gap over triple the rule's interval
    /// threshold (900s at fiveOneOne) breaks the pattern. `sustainedEvidenceSeconds`
    /// is measured from the later contraction of that break, not from episodeStart —
    /// eleven records span an hour-plus with one 1000s hole among otherwise-300s
    /// gaps; the hole alone fails sustainedMet and resets the evidence clock.
    @Test("Sustained: the hour elapses but a 1000s in-window gap (over the 900s break limit) fails sustainedMet; sustainedEvidenceSeconds reads from the break")
    func sustainedBreaksOnAnOversizedGapDespiteTheHourElapsing() {
        let offsets: [Int64] = [0, 300, 600, 900, 1200, 1500, 2500, 2800, 3100, 3400, 3700]
        let records = offsets.enumerated().map { index, offset in
            rec(index, startOffset: offset, duration: 70)
        }
        let now = t0 + 3700 + 60

        let result = OracleMath.pattern(records: records, rule: .fiveOneOne, now: now)

        #expect(result.patternLengthSeconds == 3760, "the hour itself should read as elapsed")
        #expect(result.sustainedMet == false, "the 1000s gap should break continuity")
        // continuityAnchor is the later contraction of the break (offset 2500);
        // now (3760) minus that is 1260.
        #expect(result.sustainedEvidenceSeconds == 1260)
    }

    /// Both sides of the continuity boundary itself, as decision 0026's own
    /// Boundaries section names it: an 899s (14:59) in-window gap still counts as
    /// the same pattern; 901s (15:01), just over triple the fiveOneOne interval
    /// threshold, breaks it. Everything else about the two record sets is identical.
    @Test("Sustained gap boundary: an 899s in-window gap still sustains; 901s breaks it")
    func sustainedGapBoundaryBothSides() {
        func makeResult(gap: Int64) -> OraclePattern {
            var offsets: [Int64] = [0, 300, 600, 900, 1200, 1500]
            offsets.append(offsets.last! + gap)
            for _ in 0..<4 { offsets.append(offsets.last! + 300) }
            let records = offsets.enumerated().map { index, offset in rec(index, startOffset: offset, duration: 70) }
            let now = t0 + offsets.last! + 60
            return OracleMath.pattern(records: records, rule: .fiveOneOne, now: now)
        }

        #expect(makeResult(gap: 899).sustainedMet == true)
        #expect(makeResult(gap: 901).sustainedMet == false)
    }

    /// The latch (decision 0025): presentedMet equals the raw guidelineMet exactly
    /// where raw is true — onset is immediate — and holds true afterward until raw
    /// has read continuously not-true for ten minutes.
    ///
    /// This pins the latch against a genuine **true -> false** transition (a
    /// dimension wobbling, not the evidence floor collapsing to nil — that shape is
    /// pinned separately below, in the amendment section): a clean 5-1-1 pattern
    /// (13 records, 300s apart) is followed by a second phase that widens to 400s
    /// apart — individually over the frequency threshold. At eight of eleven
    /// in-window intervals the share still clears two-thirds (raw true); 400s
    /// later, a ninth widened gap tips it to seven of eleven (raw false, floor still
    /// well above six) — and presentedMet still reads true, latched from a raw-true
    /// instant the sampling loop finds 200s further back.
    @Test("Latch: presentedMet equals guidelineMet while raw is true, and holds true 400s after raw drops (still well inside the 10-minute release)")
    func presentedMetEqualsRawThenLatchesThroughTheDrop() {
        let phase1Offsets: [Int64] = (0...12).map { Int64($0) * 300 }             // 0, 300, ..., 3600: clean
        let phase2Offsets: [Int64] = (0..<10).map { 3900 + Int64($0) * 400 }      // 3900, 4300, ...: widened
        let allOffsets = phase1Offsets + phase2Offsets

        func records(through cutoff: Int64) -> [OracleRecord] {
            allOffsets.enumerated()
                .filter { $0.element <= cutoff }
                .map { rec($0.offset, startOffset: $0.element, duration: 70) }
        }

        // Raw true: eight clean gaps and three widened ones — 8/11 clears 2/3.
        let stillRaw = OracleMath.pattern(records: records(through: 5100), rule: .fiveOneOne, now: t0 + 5200)
        #expect(stillRaw.guidelineMet == true, "setup: eight-of-eleven should still clear the share")
        #expect(stillRaw.presentedMet == true)

        // Raw false, 400s later: a fifth widened gap tips the share to 7/11 — under
        // two-thirds — while the evidence floor stays comfortably met (11 in window).
        let justDropped = OracleMath.pattern(records: records(through: 5500), rule: .fiveOneOne, now: t0 + 5600)
        #expect(justDropped.guidelineMet == false, "setup: seven-of-eleven should miss the share")
        #expect(justDropped.presentedMet == true, "the latch should still hold a verdict that was raw-true seconds ago")
    }

    // MARK: Latch — the amendment (F-0009's residual)

    /// Seven contractions, 300s apart: a 300-second continuous raw-true stretch
    /// (3600–3900) where a buffer record keeps the window at exactly the evidence
    /// floor, followed by nothing — no new record ever arrives — so the floor
    /// drains for good once the buffer is spent. Shared by the dip and release
    /// tests below.
    private func floorDrainRecords() -> [OracleRecord] {
        (0..<7).map { i in rec(i, startOffset: Int64(i) * 300, duration: 60) }
    }

    /// **F-0009's residual, closed.** `presentedMet` moved off `OraclePattern`'s
    /// tie to `guidelineMet`'s own nil-ness: a window that drains below the
    /// evidence floor used to withdraw the presented verdict instantly (54 of 69
    /// measured flaps), and now the same held verdict survives the dip and reads
    /// met again once fresh evidence clears the floor.
    @Test("Amendment: a verdict presented through an evidence-floor dip, and met again once the floor recovers")
    func dipBelowTheFloorThenRecoveringHoldsPresented() {
        let original = floorDrainRecords()

        // Raw met at the hour mark: all seven still sit inside the window.
        let met = OracleMath.pattern(records: original, rule: .fiveOneOne, now: t0 + 3600)
        #expect(met.guidelineMet == true)
        #expect(met.presentedMet == true)

        // 301s later the second record (offset 300) ages out of the window,
        // dropping the count from six to five — below the floor. The whole status
        // disappears; no dimension flipped, the evidence did.
        let dipped = OracleMath.pattern(records: original, rule: .fiveOneOne, now: t0 + 3901)
        #expect(dipped.guidelineMet == nil, "the floor itself withdrew, not a dimension")
        #expect(dipped.presentedMet == true,
                "a verdict that was raw-true thirty seconds ago must not vanish with the floor")

        // Fresh evidence — a burst bridging in at exactly the continuity limit —
        // clears the floor again well inside the ten-minute release, and the
        // pattern reads genuinely met once more.
        let recoveryOffsets: [Int64] = [2700, 3000, 3300, 3600, 3900, 4200]
        let recovered = original + recoveryOffsets.enumerated().map { index, offset in
            rec(7 + index, startOffset: offset, duration: 60)
        }
        let restored = OracleMath.pattern(records: recovered, rule: .fiveOneOne, now: t0 + 4260)
        #expect(restored.guidelineMet == true, "evidence recovered; the pattern is met again")
        #expect(restored.presentedMet == true)
    }

    /// The floor drain has no recovery this time — nothing new is ever recorded —
    /// so the ten-minute clock the amendment still runs on runs out on schedule.
    /// The last raw-true instant is 3900 (one second before the sixth record's own
    /// aging-out); release lands ten minutes and one second after that, the same
    /// closed-boundary rule every latch check in this file uses.
    @Test("Amendment: a sub-floor run with no recovery releases ten minutes after the last raw-true instant")
    func aTenMinuteSubFloorRunReleases() {
        let original = floorDrainRecords()

        #expect(OracleMath.presentedMet(records: original, rule: .fiveOneOne, now: t0 + 4500) == true,
                "exactly ten minutes past the last raw-true instant: still held")
        #expect(OracleMath.presentedMet(records: original, rule: .fiveOneOne, now: t0 + 4501) == false,
                "ten minutes and one second past: released")
    }

    /// **The no-figures guard.** A verdict the latch would otherwise hold — raw-true
    /// within the last ten minutes — must still never present with nothing to show
    /// beside it. Seven records a hundred seconds apart give the latch something
    /// genuinely raw-true to find at 3700; by 4150 only the newest record and its
    /// single bridging entry remain reachable at all — one interval short of an
    /// average — while the wider pre-check window still holds every one of the
    /// seven, so this is the guard doing the work, not the pre-check short-circuiting
    /// before it.
    @Test("Amendment: the no-figures guard withholds a held verdict once averageInterval is nil")
    func theNoFiguresGuardWithholdsAHeldVerdict() {
        let records = (0..<7).map { i in rec(i, startOffset: Int64(i) * 100, duration: 60) }

        // Setup: raw met at 3700, comfortably inside the ten-minute lookback from
        // 4150 — without the guard the latch would find this and hold.
        let setup = OracleMath.pattern(records: records, rule: .fiveOneOne, now: t0 + 3700)
        #expect(setup.guidelineMet == true)

        let later = OracleMath.pattern(records: records, rule: .fiveOneOne, now: t0 + 4150)
        #expect(later.averageInterval == nil,
                "setup: only the newest record and its single bridging entry remain reachable")
        #expect(later.presentedMet == false,
                "a held verdict must never render with no figures to show beside it")
        #expect(OracleMath.presentedMet(records: records, rule: .fiveOneOne, now: t0 + 4150) == false)
    }

    /// Fold semantics in one story: a redundant tapStart while running is a no-op; a
    /// tapEnd while idle is a no-op; a tapEnd stamped before its own start clamps to
    /// zero length instead of going negative; delete then undoDelete restores the
    /// record's identity verbatim; and clearAll empties the deleted-set too, so a
    /// following undoDelete has nothing left to restore.
    @Test("Fold semantics: redundant taps no-op, end-before-start clamps, delete/undo round-trips identity, clearAll blocks undo")
    func foldSemantics() {
        let redundantStart: [OracleAction] = [.tapStart(at: 0), .tapStart(at: 10)]
        let startResult = OracleMath.fold(redundantStart)
        #expect(startResult.count == 1)
        #expect(startResult.first?.start == 0)

        let idleEnd: [OracleAction] = [.tapEnd(at: 5)]
        #expect(OracleMath.fold(idleEnd).isEmpty)

        let clampEnd: [OracleAction] = [.tapStart(at: 100), .tapEnd(at: 50)]
        let clamped = OracleMath.fold(clampEnd)
        #expect(clamped.first?.start == 100)
        #expect(clamped.first?.end == 100)

        let deleteUndo: [OracleAction] = [
            .tapStart(at: 0), .tapEnd(at: 60),
            .deleteRecord(at: 70, createdBy: 0),
            .undoDelete(at: 80, createdBy: 0),
        ]
        let restored = OracleMath.fold(deleteUndo)
        #expect(restored.count == 1)
        #expect(restored.first?.createdBy == 0)
        #expect(restored.first?.start == 0)
        #expect(restored.first?.end == 60)

        let clearThenUndo: [OracleAction] = [
            .tapStart(at: 0), .tapEnd(at: 60),
            .deleteRecord(at: 70, createdBy: 0),
            .clearAll(at: 80),
            .undoDelete(at: 90, createdBy: 0),
        ]
        #expect(OracleMath.fold(clearThenUndo).isEmpty)
    }

    /// clockSet shifts only the actions that come after it. A -600s clockSet makes
    /// the next tapStart land 600s earlier in epoch time; the record stored before
    /// the clockSet keeps its original epoch time untouched.
    @Test("clockSet shifts only subsequent actions' effective time; already-stored records keep theirs")
    func clockSetShiftsOnlySubsequentActions() {
        let actions: [OracleAction] = [
            .tapStart(at: 1000), .tapEnd(at: 1060),
            .clockSet(at: 1070, deltaSeconds: -600),
            .tapStart(at: 2000), // effective = 2000 + (-600) = 1400
        ]
        let result = OracleMath.fold(actions)

        #expect(result.count == 2)
        #expect(result[0].start == 1000)
        #expect(result[0].end == 1060)
        #expect(result[1].start == 1400)
        #expect(result[1].end == nil)
    }

    /// Tie-break: two records sharing a start second sort by createdBy ascending, so
    /// the referee's ordering never depends on incidental array position.
    @Test("Tie-break: two records sharing a start second sort by createdBy ascending")
    func tieBreakByCreatedBy() {
        let records = [
            OracleRecord(createdBy: 5, start: t0, end: t0 + 60),
            OracleRecord(createdBy: 2, start: t0, end: t0 + 60),
        ]
        let sorted = OracleMath.sorted(records)
        #expect(sorted.map(\.createdBy) == [2, 5])
    }

    // MARK: - Fast-met (decision 0040)

    /// The share, re-run at half the threshold: four of six gaps at or inside 2:30
    /// is two-thirds and passes; three of six is a half and fails — the oracle's
    /// own reimplementation of the same boundary `PatternAnalysisTests` pins on the
    /// engine side.
    @Test("Fast frequency share: four of six gaps within half the threshold passes, three fails")
    func fastFrequencyShareBothSides() {
        // Gaps: 2, 2, 2, 2, 6, 8 minutes — four at/under 2:30, two well over.
        let passing = [0, 120, 240, 360, 480, 840, 1320].enumerated().map { i, offset in
            rec(i, startOffset: Int64(offset), duration: 60)
        }
        let passResult = OracleMath.pattern(records: passing, rule: .fiveOneOne, now: t0 + 1380)
        #expect(passResult.frequencyMet == true, "setup: the ordinary threshold is not under test")
        #expect(passResult.fastMet == true)

        // Gaps: 2, 2, 2, 10, 10, 10 minutes — three at/under 2:30, three well over.
        let failing = [0, 120, 240, 360, 960, 1560, 2160].enumerated().map { i, offset in
            rec(i, startOffset: Int64(offset), duration: 60)
        }
        let failResult = OracleMath.pattern(records: failing, rule: .fiveOneOne, now: t0 + 2220)
        #expect(failResult.fastMet == false)
    }

    /// Continuity, both sides of the limit (900s at 5-1-1, the same clause
    /// `sustainedMet` reads): a single gap over it anywhere kills fast-met however
    /// good the rest of the pattern is.
    @Test("A gap at exactly the continuity limit still fast-meets; one second over kills it")
    func fastMetContinuityBothSides() {
        func fixture(gapSeconds: Int64) -> [OracleRecord] {
            var offsets = (0..<9).map { Int64($0) * 120 }
            offsets.append(offsets.last! + gapSeconds)
            return offsets.enumerated().map { i, offset in rec(i, startOffset: offset, duration: 60) }
        }

        let atLimit = fixture(gapSeconds: 900)
        let atLimitResult = OracleMath.pattern(records: atLimit, rule: .fiveOneOne, now: t0 + 1860)
        #expect(atLimitResult.fastMet == true)

        let overLimit = fixture(gapSeconds: 901)
        let overLimitResult = OracleMath.pattern(records: overLimit, rule: .fiveOneOne, now: t0 + 1861)
        #expect(overLimitResult.fastMet == false)
    }

    /// `met` outranks `fastMet` the instant the hour completes, and the fast-met
    /// latch — tested here through `presentedFastMet` directly, the same way
    /// `presentedMet`'s own release tests above bypass `pattern`'s orchestration —
    /// holds for ten minutes past that instant and releases one second later.
    @Test("met outranks fastMet at the hour; the fast-met latch releases ten minutes later")
    func fastMetLatchReleasesTenMinutesAfterTheHourTakesOver() {
        // 30 contractions, 120s apart: 0…3480s. Well inside half the threshold for
        // the whole run, so every fast-met condition but the hour holds throughout.
        let records = (0..<30).map { i in rec(i, startOffset: Int64(i) * 120, duration: 60) }

        let justBefore = OracleMath.pattern(records: records, rule: .fiveOneOne, now: t0 + 3599)
        #expect(justBefore.guidelineMet == false)
        #expect(justBefore.fastMet == true)

        let atTheHour = OracleMath.pattern(records: records, rule: .fiveOneOne, now: t0 + 3600)
        #expect(atTheHour.guidelineMet == true)
        #expect(atTheHour.fastMet == false, "both are never true together")

        func presented(_ elapsed: Int64) -> Bool {
            OracleMath.presentedFastMet(records: records, rule: .fiveOneOne, now: t0 + 3599 + elapsed)
        }
        #expect(presented(0), "raw true is presented true, immediately")
        #expect(presented(599), "nine minutes fifty-nine seconds past the drop: still held")
        #expect(presented(600), "exactly ten minutes past the drop: still held")
        #expect(!presented(601), "ten minutes and one second past: released")
    }
}
