import Foundation

// The user-behaviour model. `Physiology` produces a noise-free `TrueContraction`
// stream on purpose — every mis-recording in the corpus has to come from here, or a
// suspect finding could never be pinned to "the body did something unusual" versus
// "a thumb did something unusual." This file is that thumb.
//
// `ReplayEngine.fold` is the ground truth for what an emitted action actually *does*
// to the store (single start/stop button, no stacking, `tapEnd` always closes the
// latest running record). Several operators below only make sense in light of that:
// a "store no-op" is a real emitted action the fold happens to ignore, not an action
// we quietly withhold — see the forgotten-stop cascade.

// MARK: - Behaviour knobs

/// What keeps the phone out of the user's hands. `rareDrive` and `sleepAndDrive` both
/// carry a hospital-drive window; only `sleepAndDrive` also carries the overnight
/// sleep window, since a partner-diligent labor tends to happen with someone awake.
public enum PauseBehaviour: Sendable, Equatable { case none, drive, sleepAndDrive, rareDrive }

/// A clock or timezone event landing on the timeline. `backSet` is the load-bearing
/// one — everything else is a display-only marker (see `placeClockEvents`).
public enum ClockEvent: String, Sendable, Equatable { case backSet, dstForward, dstBack, timezoneChange }

/// One thumb's dial settings. Every probability here is independent per contraction
/// unless documented otherwise; `Noise.actions` is what actually wires them together.
public struct NoiseProfile: Sendable, Equatable {
    public var id: NoiseProfileID
    /// Contraction never tapped at all — not even a late one.
    public var pMiss: Double
    /// Seconds; lognormal median for how late a start tap lands. `0` means no latency
    /// modeling at all (the `clean` profile).
    public var startLatencyMedian: Double
    public var startLatencySigma: Double
    /// Stop tapped early, before the contraction genuinely ended.
    public var pEarlyStop: Double
    /// Stop tap forgotten entirely — the timer keeps running in the store.
    public var pForget: Double
    /// Per subsequent contraction, chance of noticing a stuck timer.
    public var pNotice: Double
    /// A stray double-tap on an already-emitted tap — a store no-op, emitted for real
    /// so the engine has to actually prove it treats it as one.
    public var pDouble: Double
    /// A 2–10 s phantom start/stop pair dropped into genuine dead time.
    public var pPhantom: Double
    /// ... later deleted.
    public var pDeleteJunk: Double
    /// ... and the delete undone.
    public var pUndo: Double
    public var pauses: PauseBehaviour
    public var killCount: Int
    public var clockEvents: [ClockEvent]
    /// Recording starts partway into the labor — the first `k` true contractions are
    /// dropped before anything else touches the stream.
    public var pLateAdopter: Double

    public init(
        id: NoiseProfileID,
        pMiss: Double,
        startLatencyMedian: Double,
        startLatencySigma: Double,
        pEarlyStop: Double,
        pForget: Double,
        pNotice: Double,
        pDouble: Double,
        pPhantom: Double,
        pDeleteJunk: Double,
        pUndo: Double,
        pauses: PauseBehaviour,
        killCount: Int,
        clockEvents: [ClockEvent],
        pLateAdopter: Double
    ) {
        self.id = id
        self.pMiss = pMiss
        self.startLatencyMedian = startLatencyMedian
        self.startLatencySigma = startLatencySigma
        self.pEarlyStop = pEarlyStop
        self.pForget = pForget
        self.pNotice = pNotice
        self.pDouble = pDouble
        self.pPhantom = pPhantom
        self.pDeleteJunk = pDeleteJunk
        self.pUndo = pUndo
        self.pauses = pauses
        self.killCount = killCount
        self.clockEvents = clockEvents
        self.pLateAdopter = pLateAdopter
    }

    // MARK: Profile table
    //
    // `pEarlyStop` is always `pMiss / 2` and `startLatencySigma` is always 0.6 (0 for
    // `clean`) — both are derived here rather than duplicated per case, so the table
    // above can't silently drift from the one below. `clockHostile` copies
    // `typicalSolo`'s probability knobs wholesale on purpose: it exists to isolate
    // *clock* behaviour, so the thumb behind it has to be an entirely ordinary thumb.
    public static func profile(_ id: NoiseProfileID) -> NoiseProfile {
        switch id {
        case .clean:
            return NoiseProfile(
                id: .clean, pMiss: 0, startLatencyMedian: 0, startLatencySigma: 0,
                pEarlyStop: 0, pForget: 0, pNotice: 1.0, pDouble: 0, pPhantom: 0,
                pDeleteJunk: 0, pUndo: 0, pauses: .none, killCount: 0, clockEvents: [],
                pLateAdopter: 0
            )
        case .partnerDiligent:
            return NoiseProfile(
                id: .partnerDiligent, pMiss: 0.01, startLatencyMedian: 3, startLatencySigma: 0.6,
                pEarlyStop: 0.005, pForget: 0.01, pNotice: 0.35, pDouble: 0.01, pPhantom: 0.005,
                pDeleteJunk: 0.25, pUndo: 0.3, pauses: .rareDrive, killCount: 0, clockEvents: [],
                pLateAdopter: 0.05
            )
        case .typicalSolo:
            return NoiseProfile(
                id: .typicalSolo, pMiss: 0.05, startLatencyMedian: 8, startLatencySigma: 0.6,
                pEarlyStop: 0.025, pForget: 0.05, pNotice: 0.35, pDouble: 0.03, pPhantom: 0.02,
                pDeleteJunk: 0.25, pUndo: 0.3, pauses: .drive, killCount: 0, clockEvents: [],
                pLateAdopter: 0.10
            )
        case .exhaustedSolo:
            return NoiseProfile(
                id: .exhaustedSolo, pMiss: 0.15, startLatencyMedian: 20, startLatencySigma: 0.6,
                pEarlyStop: 0.075, pForget: 0.12, pNotice: 0.20, pDouble: 0.05, pPhantom: 0.03,
                pDeleteJunk: 0.25, pUndo: 0.3, pauses: .sleepAndDrive, killCount: 1, clockEvents: [],
                pLateAdopter: 0.15
            )
        case .chaotic:
            return NoiseProfile(
                id: .chaotic, pMiss: 0.20, startLatencyMedian: 25, startLatencySigma: 0.6,
                pEarlyStop: 0.10, pForget: 0.18, pNotice: 0.12, pDouble: 0.10, pPhantom: 0.08,
                pDeleteJunk: 0.5, pUndo: 0.3, pauses: .sleepAndDrive, killCount: 2,
                clockEvents: [.backSet], pLateAdopter: 0.20
            )
        case .clockHostile:
            return NoiseProfile(
                id: .clockHostile, pMiss: 0.05, startLatencyMedian: 8, startLatencySigma: 0.6,
                pEarlyStop: 0.025, pForget: 0.05, pNotice: 0.35, pDouble: 0.03, pPhantom: 0.02,
                pDeleteJunk: 0.25, pUndo: 0.3, pauses: .drive, killCount: 1,
                clockEvents: [.dstForward, .dstBack, .timezoneChange, .backSet], pLateAdopter: 0.10
            )
        }
    }
}

// MARK: - Entry point

public enum Noise: Sendable {
    /// Transforms the true stream into what the app actually received.
    /// Returns actions sorted by `at` ascending, with ties in emission order.
    public static func actions(
        trueStream: [TrueContraction],
        profile: NoiseProfile,
        rng: inout SplitMix64
    ) -> [ScenarioAction] {
        guard !trueStream.isEmpty else { return [] }

        // Late adopter, first and unconditionally: someone starts timing once they
        // believe it's real, so everything downstream — the per-contraction taps —
        // must only ever see the portion they actually recorded.
        var workingStream = trueStream
        if rng.bernoulli(profile.pLateAdopter) {
            let maxK = max(1, trueStream.count / 4)
            let k = rng.int(in: 1...maxK)
            workingStream = Array(trueStream.dropFirst(min(k, trueStream.count)))
        }
        guard !workingStream.isEmpty else { return [] }

        // Pause windows are computed off the *original* physiology stream, not the
        // late-adopter-trimmed one. The hospital-drive trigger is a property of how
        // the labor itself progressed — the drive happens *because* the pattern got
        // serious — so its timing has to correlate with the physiology regardless of
        // when the user happened to start recording. Trimming the stream first would
        // let late-adopter dropping silently erase or shift a drive that really
        // happened.
        let pauseWindows = computePauseWindows(profile: profile, trueStream: trueStream, rng: &rng)

        var engine = NoiseEngine(profile: profile, stream: workingStream, pauseWindows: pauseWindows)
        engine.run(rng: &rng)

        // Kills and clock events need the running intervals the main pass just
        // produced (to land "mid-running-contraction"), so they're necessarily a
        // second, lightweight pass rather than folded into the first.
        engine.placeKills(rng: &rng)
        engine.placeClockEvents(rng: &rng)

        return engine.finalize()
    }
}

// MARK: - Pause windows

/// `drive`, `rareDrive`, and `sleepAndDrive` all place a hospital-drive window at the
/// moment the true pattern first sustains ≤5 min start-to-start spacing for 30
/// continuous minutes — the point a real household would actually decide to leave.
/// `sleepAndDrive` also gets an overnight sleep window; `rareDrive` only takes the
/// drive 35 % of the time (a diligent partner is far more often awake and reachable).
private func computePauseWindows(
    profile: NoiseProfile,
    trueStream: [TrueContraction],
    rng: inout SplitMix64
) -> [(Int64, Int64)] {
    var windows: [(Int64, Int64)] = []
    switch profile.pauses {
    case .none:
        break
    case .drive:
        if let window = driveWindow(trueStream, rng: &rng) { windows.append(window) }
    case .rareDrive:
        // Drawn unconditionally (not short-circuited on trigger presence) so the
        // rng stream shape doesn't depend on whether this particular scenario ever
        // hit the 30-minute pattern.
        let applies = rng.bernoulli(0.35)
        if applies, let window = driveWindow(trueStream, rng: &rng) { windows.append(window) }
    case .sleepAndDrive:
        if let window = sleepWindow(trueStream, rng: &rng) { windows.append(window) }
        if let window = driveWindow(trueStream, rng: &rng) { windows.append(window) }
    }
    return windows
}

/// The first instant a run of start-to-start gaps ≤300 s has lasted ≥1800 s
/// continuously. Nil if the pattern never sustains that (a fizzle, a slow burn that
/// never firms up) — per the brief, no drive window is placed in that case.
private func findSustainedPatternStart(_ stream: [TrueContraction]) -> Int64? {
    guard stream.count >= 2 else { return nil }
    var runStart = stream[0].start
    for i in 1..<stream.count {
        let spacing = stream[i].start - stream[i - 1].start
        if spacing <= 300 {
            if stream[i].start - runStart >= 1800 {
                return runStart + 1800
            }
        } else {
            runStart = stream[i].start
        }
    }
    return nil
}

/// **A pause may never swallow the labor it interrupts.**
///
/// The sampled windows below are sized for a long labor — 1–4 h of sleep, up to an
/// hour of driving. Applied verbatim to a two-hour precipitous birth they cover the
/// entire stream, and the scenario silently becomes an empty one: no taps, nothing
/// for the engine to be right or wrong about. That is not a hard test case, it is a
/// missing one, and it was costing the corpus every short archetype under exactly
/// the two profiles most likely to expose bugs. It is also clinically absurd —
/// nobody sleeps through a precipitous labor.
///
/// So each window is capped at a fraction of the span it sits in. The draw happens
/// first and is clamped afterwards, never skipped: the generator's stream position
/// must not depend on how long a given labor happened to be.
private let maxPauseFractionOfSpan = 0.35
private let maxDriveFractionOfRemainder = 0.4

private func driveWindow(_ trueStream: [TrueContraction], rng: inout SplitMix64) -> (Int64, Int64)? {
    let sampled = Int64(rng.uniform(in: 1200...3600).rounded())  // 20-60 min
    guard let trigger = findSustainedPatternStart(trueStream),
          let last = trueStream.last else { return nil }

    let remainder = max(0, last.end - trigger)
    let cap = Int64((Double(remainder) * maxDriveFractionOfRemainder).rounded())
    let duration = min(sampled, cap)
    // A drive shorter than a couple of contractions is indistinguishable from a
    // missed tap and not worth modelling as a pause.
    guard duration >= 300 else { return nil }
    return (trigger, trigger + duration)
}

/// One sleep window placed uniformly in the first 60 % of the stream's span — sleep
/// happens early in a long labor, not at the tail end of it — and never longer than
/// `maxPauseFractionOfSpan` of that span.
private func sleepWindow(_ trueStream: [TrueContraction], rng: inout SplitMix64) -> (Int64, Int64)? {
    let sampled = Int64(rng.uniform(in: 3600...14400).rounded())  // 1-4 h
    guard let first = trueStream.first, let last = trueStream.last else { return nil }

    let totalStart = first.start
    let totalEnd = last.end
    let span = max(0, totalEnd - totalStart)
    let duration = min(sampled, Int64((Double(span) * maxPauseFractionOfSpan).rounded()))
    // Below half an hour it is not a night's sleep, it is a nap nobody takes mid-labor.
    guard duration >= 1800 else { return nil }

    let sixtyPercentPoint = totalStart + Int64((Double(span) * 0.6).rounded())
    let latestStart = max(totalStart, sixtyPercentPoint - duration)
    let windowStart = latestStart > totalStart
        ? Int64(rng.uniform(in: Double(totalStart)...Double(latestStart)).rounded())
        : totalStart
    return (windowStart, windowStart + duration)
}

// MARK: - Engine

private enum TapKind { case start, end }

/// All the per-scenario mutable state the operators share: the growing action list
/// (with placeholder identity tokens for phantom records), the running-interval
/// bookkeeping kill/clock placement needs, and the pause windows every tap gets
/// checked against.
///
/// `createdBy` addressing is the sharp edge here: `deleteRecord`/`undoDelete` name the
/// index of the *creating* action in the FINAL sorted array, but we don't know final
/// indices while emitting — only emission order. So every action is emitted with an
/// integer token (its own emission order, monotonically increasing) standing in for
/// that unknown final index; `finalize()` sorts once, builds token → final-index, and
/// rewrites the delete/undo actions' `createdBy` in a second pass. Tokens and final
/// indices share the same non-negative integer space by construction, but they are
/// never mixed except through that explicit rewrite.
private struct NoiseEngine {
    let profile: NoiseProfile
    let stream: [TrueContraction]
    let pauseWindows: [(Int64, Int64)]
    let overallEnd: Int64

    private var raw: [(token: Int, action: ScenarioAction)] = []
    private var nextToken = 0
    /// Recorded (start, end) of every genuinely-open running interval — including the
    /// long-stuck ones a forgotten stop produces — for kill/backSet placement.
    private var trueTapIntervals: [(start: Int64, end: Int64)] = []

    init(profile: NoiseProfile, stream: [TrueContraction], pauseWindows: [(Int64, Int64)]) {
        self.profile = profile
        self.stream = stream
        self.pauseWindows = pauseWindows
        self.overallEnd = stream.last?.end ?? 0
    }

    @discardableResult
    private mutating func emit(_ action: ScenarioAction) -> Int {
        let token = nextToken
        raw.append((token, action))
        nextToken += 1
        return token
    }

    private func isPaused(_ time: Int64) -> Bool {
        pauseWindows.contains { time >= $0.0 && time <= $0.1 }
    }

    /// The one place any literal tap enters the corpus: pause suppression and the
    /// double-tap roll both live here so every tap — main, phantom, or a forgotten
    /// stop's no-op attempt — gets them uniformly, rather than each call site having
    /// to remember to re-implement both. Returns the *primary* tap's token (the one
    /// that actually creates a record, if any), or nil if the pause window swallowed
    /// it — a double-tap duplicate never gets its own token, since a duplicate can
    /// never be what a delete/undo addresses.
    @discardableResult
    private mutating func emitTap(_ kind: TapKind, at time: Int64, rng: inout SplitMix64) -> Int? {
        guard !isPaused(time) else { return nil }
        let token = emit(kind == .start ? .tapStart(at: time) : .tapEnd(at: time))
        if rng.bernoulli(profile.pDouble) {
            let dupAt = time + Int64(rng.uniform(in: 1...3).rounded())
            emit(kind == .start ? .tapStart(at: dupAt) : .tapEnd(at: dupAt))
        }
        return token
    }

    // MARK: Main pass

    mutating func run(rng: inout SplitMix64) {
        var i = 0
        while i < stream.count {
            let c = stream[i]

            // Missed contraction — nothing tapped at all, but the dead time after it
            // can still grow a phantom pair.
            if rng.bernoulli(profile.pMiss) {
                if i + 1 < stream.count {
                    tryPhantomPair(gapStart: c.end, gapEnd: stream[i + 1].start, rng: &rng)
                }
                i += 1
                continue
            }

            let startAt = lateStartTime(c, rng: &rng)
            guard emitTap(.start, at: startAt, rng: &rng) != nil else {
                // The start tap itself landed inside a pause window: nobody was
                // there to make it, so there is nothing to resolve an end for either.
                i += 1
                continue
            }

            i = resolveEnd(startIndex: i, startAt: startAt, rng: &rng)
        }
    }

    /// `L = exp(ln(median) + sigma * Z)`, clamped to `[0, min(40, duration - 5)]`.
    /// The upper bound is floored at 0 before clamping — a sub-5-second true
    /// contraction would otherwise hand `min` an inverted, empty range.
    private func lateStartTime(_ c: TrueContraction, rng: inout SplitMix64) -> Int64 {
        guard profile.startLatencyMedian > 0 else { return c.start }
        let z = rng.normal(truncatedTo: 2.5)
        let lateness = exp(log(profile.startLatencyMedian) + profile.startLatencySigma * z)
        let upperBound = max(0.0, Double(min(Int64(40), max(Int64(0), c.durationSeconds - 5))))
        let clamped = min(max(lateness, 0), upperBound)
        return c.start + Int64(clamped.rounded())
    }

    /// Resolves how contraction `startIndex` (already tapped-in at `startAt`) actually
    /// ends, cascading through as many forgotten-stop chains as the dice produce, and
    /// returns the next stream index the caller should resume at.
    ///
    /// A forgotten stop is the corpus's most consequential failure mode: the store's
    /// running record has to survive purely on its stored start time, with the app
    /// process itself possibly restarting in between (see `placeKills`) — nothing
    /// about "a contraction is in progress" lives in memory. `ReplayEngine.fold`
    /// refuses to stack a second `tapStart` while one is running, so every intervening
    /// contraction's habitual start-tap is emitted for real and is a genuine store
    /// no-op — exactly the same shape as a double-tap, not an omission. They "vanish
    /// from the record" in the sense that matters: no `SimRecord` is ever created for
    /// them, even though the raw tap is right there in the action list.
    private mutating func resolveEnd(startIndex: Int, startAt: Int64, rng: inout SplitMix64) -> Int {
        var i = startIndex
        var openAt = startAt

        while true {
            let c = stream[i]

            if rng.bernoulli(profile.pForget) {
                let n = rng.geometricTrials(p: profile.pNotice)
                let remaining = stream.count - 1 - i  // contractions strictly after i

                guard n <= remaining else {
                    // Never noticed before the stream ends. The habitual (no-op)
                    // start-tap still fires for everything left — the record itself
                    // never closes.
                    for j in (i + 1)..<stream.count {
                        emitTap(.start, at: stream[j].start, rng: &rng)
                    }
                    trueTapIntervals.append((start: openAt, end: overallEnd))
                    return stream.count
                }

                for j in (i + 1)..<(i + n) {
                    emitTap(.start, at: stream[j].start, rng: &rng)
                }

                let noticeIndex = i + n
                let noticeC = stream[noticeIndex]
                // Same instant: tapEnd (finally closing the stuck record) must sort
                // before tapStart (the contraction that made them notice) — see the
                // tie-break in `finalize()` — or the new start would itself be
                // swallowed as a no-op against the record it was meant to replace.
                emitTap(.end, at: noticeC.start, rng: &rng)
                trueTapIntervals.append((start: openAt, end: noticeC.start))

                guard emitTap(.start, at: noticeC.start, rng: &rng) != nil else {
                    // The notice moment itself fell in a pause window: rare, but
                    // then neither the close nor the reopen actually happened.
                    return noticeIndex + 1
                }
                i = noticeIndex
                openAt = noticeC.start
                continue  // this fresh start now needs its own end resolved
            }

            let endAt: Int64
            if rng.bernoulli(profile.pEarlyStop) {
                endAt = c.start + Int64((Double(c.durationSeconds) * rng.uniform(in: 0.4...0.9)).rounded())
            } else {
                endAt = c.end
            }
            if emitTap(.end, at: endAt, rng: &rng) != nil {
                trueTapIntervals.append((start: openAt, end: endAt))
            } else {
                // The stop tap itself landed in a pause window: left open. Rare
                // (pause windows run hours, a stop tap is a single instant), and not
                // worth a second bookkeeping path — record an approximate interval so
                // kill placement still has something to work with.
                trueTapIntervals.append((start: openAt, end: min(endAt + 1, overallEnd)))
            }

            if i + 1 < stream.count {
                tryPhantomPair(gapStart: c.end, gapEnd: stream[i + 1].start, rng: &rng)
            }
            return i + 1
        }
    }

    // MARK: Phantom pairs

    /// A 2–10 s stray start/stop pair dropped into genuine dead time (>120 s), with a
    /// chance of being deleted and — of those — a chance of the delete being undone.
    /// `createdBy` on the delete/undo is the phantom's own `tapStart` token: nothing
    /// else in this model ever deletes or undoes a *real* contraction's record.
    private mutating func tryPhantomPair(gapStart: Int64, gapEnd: Int64, rng: inout SplitMix64) {
        guard gapEnd - gapStart > 120 else { return }
        guard rng.bernoulli(profile.pPhantom) else { return }

        let duration = Int64(rng.uniform(in: 2...10).rounded())
        let latestStart = gapEnd - duration
        guard latestStart > gapStart else { return }
        let phantomStart = Int64(rng.uniform(in: Double(gapStart)...Double(latestStart)).rounded())
        let phantomEnd = phantomStart + duration

        guard let startToken = emitTap(.start, at: phantomStart, rng: &rng) else { return }
        emitTap(.end, at: phantomEnd, rng: &rng)

        guard rng.bernoulli(profile.pDeleteJunk) else { return }
        let deleteAt = phantomEnd + Int64(rng.uniform(in: 30...600).rounded())
        emit(.deleteRecord(at: deleteAt, createdBy: startToken))

        guard rng.bernoulli(profile.pUndo) else { return }
        let undoAt = deleteAt + Int64(rng.uniform(in: 10...120).rounded())
        emit(.undoDelete(at: undoAt, createdBy: startToken))
    }

    // MARK: App kills

    /// `killCount` kill/launch pairs, spread across the recorded running intervals
    /// (including the long-stuck ones a forgotten stop leaves behind) so each one has
    /// the best chance of landing mid-running-contraction — the case that actually
    /// matters, since running state has to survive purely on what's in the store, not
    /// on anything held in memory by a process that just died.
    mutating func placeKills(rng: inout SplitMix64) {
        guard profile.killCount > 0 else { return }
        for k in 0..<profile.killCount {
            let at: Int64
            if !trueTapIntervals.isEmpty {
                let idx = min(k * trueTapIntervals.count / profile.killCount, trueTapIntervals.count - 1)
                let interval = trueTapIntervals[idx]
                let span = max(interval.end - interval.start, 1)
                at = interval.start + Int64(rng.uniform(in: 0...Double(span)).rounded())
            } else {
                // No running interval to land in (a degenerate all-missed stream);
                // fall back to spreading evenly across the timeline rather than
                // dropping the kill.
                let firstStart = stream.first?.start ?? 0
                let span = max(overallEnd - firstStart, 1)
                let fraction = Double(k + 1) / Double(profile.killCount + 1)
                at = firstStart + Int64((Double(span) * fraction).rounded())
            }
            emit(.killApp(at: at))
            let resumeDelay = Int64(rng.uniform(in: 5...300).rounded())
            emit(.launchApp(at: at + resumeDelay))
        }
    }

    // MARK: Clock events

    /// `backSet` is placed mid-running-contraction, same rationale as a kill: it's
    /// the case that actually exercises whether a stored duration survives a clock
    /// move. The other three are display-only markers spread evenly across the
    /// timeline in the order the profile lists them (so `dstForward` precedes
    /// `dstBack`, spring before fall).
    mutating func placeClockEvents(rng: inout SplitMix64) {
        guard !profile.clockEvents.isEmpty else { return }
        let firstStart = stream.first?.start ?? 0
        let span = max(overallEnd - firstStart, 1)
        let nonBackSetTotal = profile.clockEvents.filter { $0 != .backSet }.count
        var nonBackSetSeen = 0

        for event in profile.clockEvents {
            switch event {
            case .backSet:
                let at: Int64
                if trueTapIntervals.isEmpty {
                    at = firstStart + span / 2
                } else {
                    let interval = trueTapIntervals[trueTapIntervals.count / 2]
                    at = interval.start + (interval.end - interval.start) / 2
                }
                let delta = -Int64(rng.uniform(in: 120...600).rounded())
                emit(.clockSet(at: at, deltaSeconds: delta))

            case .dstForward, .dstBack:
                // Same identifier before and after: DST shifts the UTC offset, not
                // the IANA region, so there is no real-world "timezone changed" event
                // for it either — this just restamps the marker instant. The engine
                // is wall-clock throughout; asserting that not one stored second
                // moves is the entire point of carrying this action at all.
                nonBackSetSeen += 1
                let fraction = Double(nonBackSetSeen) / Double(nonBackSetTotal + 1)
                let at = firstStart + Int64((Double(span) * fraction).rounded())
                emit(.timezoneChange(at: at, identifier: "America/New_York"))

            case .timezoneChange:
                nonBackSetSeen += 1
                let fraction = Double(nonBackSetSeen) / Double(nonBackSetTotal + 1)
                let at = firstStart + Int64((Double(span) * fraction).rounded())
                emit(.timezoneChange(at: at, identifier: "Europe/London"))
            }
        }
    }

    // MARK: Finalize

    /// Sorts (stable, `at` ascending, with the notice-triggered tapEnd-before-tapStart
    /// tie-break), then rewrites every delete/undo's placeholder token into the final
    /// index of the tapStart action it names. Two passes because the token → index
    /// mapping only exists *after* the sort — see the type-level doc comment.
    func finalize() -> [ScenarioAction] {
        let sorted = raw.sorted { lhs, rhs in
            if lhs.action.at != rhs.action.at { return lhs.action.at < rhs.action.at }
            let lhsEndBeforeStart = lhs.action.kind == .tapEnd && rhs.action.kind == .tapStart
            let rhsEndBeforeStart = rhs.action.kind == .tapEnd && lhs.action.kind == .tapStart
            if lhsEndBeforeStart { return true }
            if rhsEndBeforeStart { return false }
            return lhs.token < rhs.token  // stable fallback: original emission order
        }

        var finalIndex: [Int: Int] = [:]
        finalIndex.reserveCapacity(sorted.count)
        for (index, entry) in sorted.enumerated() {
            finalIndex[entry.token] = index
        }

        return sorted.map { entry in
            switch entry.action {
            case let .deleteRecord(at, createdByToken):
                return .deleteRecord(at: at, createdBy: finalIndex[createdByToken] ?? createdByToken)
            case let .undoDelete(at, createdByToken):
                return .undoDelete(at: at, createdBy: finalIndex[createdByToken] ?? createdByToken)
            default:
                return entry.action
            }
        }
    }
}
