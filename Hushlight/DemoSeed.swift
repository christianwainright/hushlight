import Foundation
import LaborKit
import SwiftData

#if DEBUG
/// SP-184's instrument: launch-argument seeding so the simulated-labor pass can put
/// the app into the states that matter without an hour of thumb work. DEBUG-only by
/// construction — release builds do not contain this file's behaviour, so no shipped
/// build can ever wipe or invent a labor record.
enum DemoSeed {
    /// `-seedLabor511` — a textbook send-off: every 5 minutes, 62 s each, for 70
    /// minutes, the newest two minutes ago. All three guideline dimensions met, so
    /// the banner must render.
    ///
    /// `-seedLaborYoung` — a strong pattern 25 minutes old: every 4 minutes, 62 s
    /// each. Frequency and duration met, sustained not — the partial line must
    /// render and the banner must NOT.
    ///
    /// `-seedLaborNearMet` — HL-003 slice 4's dawn-edge fixture: a textbook 5-1-1
    /// pattern (frequency and duration already met) whose sustained hour is missing
    /// by seconds, so the verdict flips false→true on glass roughly 30–60 s after
    /// launch rather than requiring a fourth tap. See `applyNearMet` for the
    /// arithmetic that pins the flip to a specific second.
    ///
    /// `-seedLaborMidnight` — SP-214's crossing fixture: an episode pinned to start
    /// at 23:40 on the calendar day *before* launch's, textbook 5-1-1 spacing
    /// carried forward across the midnight in between to a contraction that ended
    /// recently. Puts the header in its "SINCE YESTERDAY …" state and History in
    /// its inline day-marker state on demand, regardless of what day it actually is
    /// when this runs. See `applyMidnight`.
    ///
    /// `-seedLaborFast` — decision 0040's textbook precipitous send-off: every 2
    /// minutes, 80 s each, for 30 minutes, the newest two minutes ago. Frequency
    /// sits at half the 5-1-1 threshold (well past the fast-met bar), duration and
    /// continuity hold, and the pattern easily clears the twenty-minute floor —
    /// but the sustained hour is nowhere near met, so the fast-met banner must
    /// render and the ordinary met banner must NOT.
    ///
    /// `-seedLaborConcluded` — SP-215's recap fixture: the exact textbook 5-1-1
    /// shape `-seedLabor511` seeds (every 5 minutes, 62 s each, 70 minutes of it),
    /// walked back so its newest contraction ends a full day past
    /// `EpisodeClosure.recapThreshold` rather than two minutes ago. Nothing about
    /// the pattern arithmetic differs from `-seedLabor511`'s own send-off — only
    /// how long ago it happened — so the timer screen has to be in its closure
    /// recap state on launch, not the ordinary met banner. See `applyConcluded`.
    ///
    /// `-seedLaborTightening` — decision 0043's fixture: an ~8:30 stretch for the
    /// pattern's older ~42 minutes, tightening to an ~5:30 stretch for its newest
    /// ~33 — built so the trailing-hour window and the hour before it land on
    /// opposite sides of the change and disagree past the trend's one-sixth noise
    /// floor, and History's caption must render under the current episode. See
    /// `applyTightening`.
    ///
    /// `-seedLaborSecondNight` — decision 0050's fixture, and the only scenario here
    /// that seeds **two** stretches: last night ~8:30 apart, tonight ~8:24 and still
    /// running. The two whole-stretch means differ by 6 s against a 510 s reference, so
    /// History's comparison must read *about the same as your last stretch* — the
    /// steady reading the decision turns on, which no single-stretch seed can produce.
    /// See `applySecondNight`.
    /// HL-054: **the App Store Review recording needs a met verdict that survives more
    /// than one take.**
    ///
    /// `-seedLabor511` anchors its pattern to the moment it runs, and the verdict
    /// decays: the guideline wants an hour sustained, the seed lays down seventy
    /// minutes, and `PatternAnalysis.latchRelease` holds it ten minutes past that — so
    /// fifteen to twenty minutes after seeding the banner steps down to its held form.
    /// Fine for one take, useless for six, and a phone cannot pass itself a launch
    /// argument from the Home Screen.
    ///
    /// So the flag is *sticky*: pass `-seedLabor511Always` once over the cable and
    /// every cold launch afterwards re-seeds a fresh send-off. `-seedLaborDemoOff` and
    /// `-seedLaborWipe` both turn it off.
    ///
    /// It works by **adding `-seedLabor511` to the arguments the rest of this file
    /// already reads**, rather than seeding on its own — one plan, one code path, and
    /// nothing to drift.
    ///
    /// **It cannot ship, and not because this added a guard.** The whole file is inside
    /// `#if DEBUG` already (see the type's own comment), so `release.yml`'s Release
    /// archive contains none of it — verified rather than assumed: a Release build of
    /// this app contains no occurrence of `seedLabor511`, `seedLaborWipe` or
    /// `demoAlways511` anywhere in its binary. A demo mode that *could* ship would be a
    /// different and much worse thing; this one has no way to.
    private static let stickyDemoKey = "demoAlways511"
    private static let stickyDemoNumberKey = "demoAlways511Number"

    private static func stickyDemoArguments(_ args: [String]) -> [String] {
        let defaults = UserDefaults.standard
        if args.contains("-seedLaborDemoOff") || args.contains("-seedLaborWipe") {
            defaults.removeObject(forKey: stickyDemoKey)
            defaults.removeObject(forKey: stickyDemoNumberKey)
            return args
        }
        if args.contains("-seedLabor511Always") {
            defaults.set(true, forKey: stickyDemoKey)
            // The provider number has to be remembered with the flag, not just applied
            // once. `applyProviderNumber` *clears* the stored number whenever it sees a
            // seed flag without an explicit `-seedProviderNumber` — a deliberate rule,
            // so a QA pass cannot leave a device offering to dial a fake provider — and
            // re-injecting `-seedLabor511` every launch trips exactly that. Without
            // this the Call button vanishes on the second launch, which is the one
            // being recorded.
            defaults.set(argument(after: "-seedProviderNumber", in: args),
                         forKey: stickyDemoNumberKey)
        }
        guard defaults.bool(forKey: stickyDemoKey),
              !args.contains("-seedLabor511") else { return args }
        var injected = args + ["-seedLabor511"]
        if !args.contains("-seedProviderNumber"),
           let number = defaults.string(forKey: stickyDemoNumberKey) {
            injected += ["-seedProviderNumber", number]
        }
        return injected
    }

    static func applyIfRequested(context: ModelContext, now: Date = Date()) {
        let args = stickyDemoArguments(CommandLine.arguments)

        applyProviderNumber(args)

        // `-seedLaborWipe` — the exit path: clears every record so a verification
        // device leaves the pass with an empty store, not a synthetic labor that
        // would read as real history. A seeded pattern must never outlive the pass.
        if args.contains("-seedLaborWipe") {
            try? wipe(context)
            // F-0020's other edge: a v2 scenario can persist a rule the device
            // did not have before (a rule-switch shot judged at 4-1-1 or 3-1-1).
            // That write must not outlive the pass either, or a QA sweep leaves a
            // real device silently judging against a rule nobody chose.
            // `removeObject` rather than writing `.fiveOneOne` explicitly: no
            // stored value already *is* the default (`GuidelineRule.persisted`),
            // so this can't drift from whatever "default" means later.
            UserDefaults.standard.removeObject(forKey: GuidelineRule.defaultsKey)
            return
        }

        // `-laborScenario <absolute-path>` — the QA harness's precise seeding path
        // (Phase 1): a JSON `LaborSeedSnapshot` of exact contraction offsets from
        // `now`, replayed verbatim rather than generated from a spacing/total pair.
        // Checked before the named plans below so the harness's exact fixtures
        // always win over the coarse hand-picked scenarios.
        if let path = argument(after: "-laborScenario", in: args) {
            applyScenario(atPath: path, context: context, now: now)
            return
        }

        // `-seedLaborNearMet` gets its own branch rather than joining the
        // spacing/total plans below: those are anchored backward from "newest ends
        // 2 minutes ago" and only pin the *newest* contraction, leaving
        // `episodeStart` wherever the spacing happens to land. This scenario has to
        // pin `episodeStart` itself to the second, so it is built forward instead.
        if args.contains("-seedLaborNearMet") {
            applyNearMet(context: context, now: now)
            return
        }

        // `-seedLaborMidnight` needs the same treatment: `episodeStart` has to land
        // on a specific calendar day (the one before launch's), not just some
        // number of minutes back, so it too is built forward from a pinned start
        // rather than backward from `now`.
        if args.contains("-seedLaborMidnight") {
            applyMidnight(context: context, now: now)
            return
        }

        // `-seedLaborIrregular` — SP-209 / decision 0041's state: spacing that
        // varies before it settles. The uniform spacing/total plans below cannot
        // express it, so it builds its own cycle: gaps walking 7–12 minutes,
        // range ratio 12/7 ≈ 1.71 (past the 1.5× wide bound) and mean ≈ 9:24
        // (past 7:30, 1.5× the 5-1-1 threshold) — the rest note's exact
        // territory, with the verdict correctly nowhere near.
        if args.contains("-seedLaborIrregular") {
            applyIrregular(context: context, now: now)
            return
        }

        // `-seedLaborConcluded` needs its own branch for the same reason
        // `-seedLaborMidnight` does: it is anchored to a specific instant days
        // back, not to "the newest contraction ends a couple of minutes ago" the
        // spacing/total plans below all share.
        if args.contains("-seedLaborConcluded") {
            applyConcluded(context: context, now: now)
            return
        }

        // `-seedLaborTightening` needs its own branch too: it is two spacings
        // back to back, not one spacing/total pair the plans below can express.
        if args.contains("-seedLaborTightening") {
            applyTightening(context: context, now: now)
            return
        }

        // `-seedLaborSecondNight` needs its own branch for a reason none of the others
        // do: it seeds *two* episodes. Every plan below builds one stretch anchored to
        // "newest ends a couple of minutes ago", and decision 0050's caption cannot
        // render against one.
        if args.contains("-seedLaborSecondNight") {
            applySecondNight(context: context, now: now)
            return
        }

        let plan: (spacingMinutes: Double, totalMinutes: Double, durationSeconds: Double)?
        if args.contains("-seedLabor511") {
            plan = (spacingMinutes: 5, totalMinutes: 70, durationSeconds: 62)
        } else if args.contains("-seedLaborYoung") {
            plan = (spacingMinutes: 4, totalMinutes: 25, durationSeconds: 62)
        } else if args.contains("-seedLaborFast") {
            plan = (spacingMinutes: 2, totalMinutes: 30, durationSeconds: 80)
        } else {
            plan = nil
        }
        guard let plan else { return }

        do {
            // A seed run replaces the store wholesale: mixing synthetic and real
            // records would poison the very averages the pass exists to verify.
            try wipe(context)

            // Newest contraction ends ~2 minutes ago; the series walks backwards.
            var start = now.addingTimeInterval(-2 * 60 - plan.durationSeconds)
            let earliest = now.addingTimeInterval(-plan.totalMinutes * 60)
            while start >= earliest {
                context.insert(
                    ContractionRecord(
                        startedAt: start,
                        endedAt: start.addingTimeInterval(plan.durationSeconds)
                    )
                )
                start = start.addingTimeInterval(-plan.spacingMinutes * 60)
            }
            try context.save()
        } catch {
            assertionFailure("Demo seed failed: \(error)")
        }
    }

    /// `-seedProviderNumber <value>` — puts SP-200's Call button on screen without a
    /// hand-typed field, so the accessibility audit and the QA pass can see the state
    /// where the verdict actually offers the call.
    ///
    /// Reconciled on **every** seeded launch rather than only when the flag is
    /// present: the number lives in defaults, so a leg that set one would otherwise
    /// leave the button on screen for every later leg on the same install, and the
    /// audit's states would depend on the order its tests happened to run in. A
    /// launch with no seeding flags at all is left alone — hand use of a debug build
    /// is not a QA pass.
    private static func applyProviderNumber(_ args: [String]) {
        // The wipe wins over an explicit number, and deliberately: it is the pass's
        // exit path, and a device that leaves a QA run still offering to dial a
        // fake provider is the same leftover F-0020 fixed for the rule.
        if args.contains("-seedLaborWipe") {
            UserDefaults.standard.removeObject(forKey: ProviderContact.defaultsKey)
        } else if let number = argument(after: "-seedProviderNumber", in: args) {
            UserDefaults.standard.set(number, forKey: ProviderContact.defaultsKey)
        } else if args.contains(where: seedFlags.contains) {
            UserDefaults.standard.removeObject(forKey: ProviderContact.defaultsKey)
        }
    }

    /// Every argument that means "this launch is a QA pass, not a person using the
    /// app". Named once so a new seeding flag cannot forget to reconcile defaults.
    private static let seedFlags: Set<String> = [
        "-seedLaborWipe", "-seedLabor511", "-seedLaborYoung", "-seedLaborNearMet",
        "-seedLaborMidnight", "-seedLaborFast", "-seedLaborIrregular", "-seedLaborConcluded",
        "-seedLaborTightening", "-seedLaborSecondNight", "-laborScenario",
        "-seedProviderNumber",
    ]

    /// `-seedLaborNearMet`'s arithmetic. Frequency and duration are met the
    /// ordinary way (five-minute spacing, 62 s contractions — the same textbook
    /// numbers `-seedLabor511` seeds); the one figure this scenario controls to the
    /// second is `episodeStart`, because `PatternAnalysis.rawPattern` reads
    /// `patternLength` as `now - episodeStart` against the *live* clock every time
    /// the screen re-renders, not a value fixed at launch. Pin `episodeStart` to
    /// `rule.sustainedWindow` minus `nearMetGapSeconds` and the sustained leg
    /// finishes itself, on the device's own clock, with nothing re-arming a timer.
    private static func applyNearMet(context: ModelContext, now: Date) {
        let spacing: TimeInterval = 5 * 60
        let duration: TimeInterval = 62
        // Comfortably inside the 30–60 s window the flip has to land in, with room
        // either side for the seconds a launch and a screenshot actually take.
        let nearMetGapSeconds: TimeInterval = 45
        let sustainedWindow = GuidelineRule.fiveOneOne.sustainedWindow.timeIntervalValue

        do {
            try wipe(context)

            // Walked forward from the pinned `episodeStart`, not backward from
            // `now` the way the plans above are — the newest contraction lands
            // wherever the spacing puts it, a few minutes back, which is fine: the
            // figure this scenario stakes everything on is the first one.
            var start = now.addingTimeInterval(-(sustainedWindow - nearMetGapSeconds))
            // The same margin `-seedLabor511` leaves so the newest contraction
            // reads as recently ended rather than mid-tap.
            let newestNoLaterThan = now.addingTimeInterval(-2 * 60 - duration)
            while start <= newestNoLaterThan {
                context.insert(
                    ContractionRecord(
                        startedAt: start,
                        endedAt: start.addingTimeInterval(duration)
                    )
                )
                start = start.addingTimeInterval(spacing)
            }
            try context.save()
        } catch {
            assertionFailure("Demo seed failed: \(error)")
        }
    }

    /// SP-209's irregular early stretch — see the dispatch comment. Newest ends
    /// two minutes ago like the plan seeds; the cycle walks backward through
    /// ninety minutes of honestly uneven spacing.
    private static func applyIrregular(context: ModelContext, now: Date) {
        do {
            try wipe(context)
            let gapsMinutes: [Double] = [7, 12, 8, 11, 9, 10, 7.5, 11.5, 9.5]
            var start = now.addingTimeInterval(-2 * 60 - 55)
            var gapIndex = 0
            let earliest = now.addingTimeInterval(-90 * 60)
            while start >= earliest {
                context.insert(
                    ContractionRecord(startedAt: start, endedAt: start.addingTimeInterval(55))
                )
                start = start.addingTimeInterval(-gapsMinutes[gapIndex % gapsMinutes.count] * 60)
                gapIndex += 1
            }
            try context.save()
        } catch {
            assertionFailure("DemoSeed irregular failed: \(error)")
        }
    }

    /// `-seedLaborConcluded`'s arithmetic (SP-215). The same shape
    /// `-seedLabor511` seeds (5-minute spacing, 62 s contractions, 70 minutes of
    /// them) — the only change is the anchor: `-seedLabor511` ends its newest
    /// contraction two minutes before `now`, this one ends it a full day past
    /// `EpisodeClosure.recapThreshold` before `now`. Built by shifting that same
    /// two-anchor loop back by exactly the difference between the two margins,
    /// so a change to the 511 plan's own numbers cannot quietly drift this
    /// fixture out of its textbook shape.
    private static func applyConcluded(context: ModelContext, now: Date) {
        let spacing: TimeInterval = 5 * 60
        let duration: TimeInterval = 62
        let totalMinutes: Double = 70
        // A full day clear of the threshold itself, so a slow launch or a
        // screenshot pass taken a few seconds late never lands the fixture on
        // the wrong side of the boundary it exists to sit well past.
        let newestEndedAgo = EpisodeClosure.recapThreshold.timeIntervalValue + 24 * 60 * 60

        do {
            try wipe(context)
            var start = now.addingTimeInterval(-newestEndedAgo - duration)
            let earliest = now.addingTimeInterval(-newestEndedAgo - totalMinutes * 60)
            while start >= earliest {
                context.insert(
                    ContractionRecord(startedAt: start, endedAt: start.addingTimeInterval(duration))
                )
                start = start.addingTimeInterval(-spacing)
            }
            try context.save()
        } catch {
            assertionFailure("Demo seed failed: \(error)")
        }
    }

    /// `-seedLaborTightening`'s arithmetic (decision 0043). Two spacings back to
    /// back, newest first: an ~5:30 stretch for ~33 minutes, continuing into an
    /// ~8:30 stretch for ~42 minutes further back — the same contiguous
    /// loose-then-tight shape the trend engine's own package tests solve exactly,
    /// chosen here so both the trailing-hour window and the hour before it clear
    /// their own two-interval floor and land almost a full minute clear of the
    /// window boundaries at 60 and 120 minutes back, which is what keeps the
    /// fixture from flipping on a slow launch or a screenshot taken a few seconds
    /// late.
    ///
    /// 8.5-minute spacing rather than a round 8:00 is deliberate, not decorative:
    /// a clean 8:00/8:00 grid puts a contraction within a second of the 60- and
    /// 120-minute marks, and this fixture's whole point is sitting well clear of
    /// them.
    private static func applyTightening(context: ModelContext, now: Date) {
        let tightSpacing: TimeInterval = 5.5 * 60
        let looseSpacing: TimeInterval = 8.5 * 60
        let duration: TimeInterval = 62
        let tightGaps = 6   // ~33 minutes, newest ending the usual ~2 minutes ago
        let looseGaps = 5   // ~42 minutes further back

        var starts: [Date] = []
        var start = now.addingTimeInterval(-2 * 60 - duration)
        starts.append(start)
        for _ in 0..<tightGaps {
            start = start.addingTimeInterval(-tightSpacing)
            starts.append(start)
        }
        for _ in 0..<looseGaps {
            start = start.addingTimeInterval(-looseSpacing)
            starts.append(start)
        }

        do {
            try wipe(context)
            for point in starts {
                context.insert(
                    ContractionRecord(startedAt: point, endedAt: point.addingTimeInterval(duration))
                )
            }
            try context.save()
        } catch {
            assertionFailure("Demo seed failed: \(error)")
        }
    }

    /// Decision 0050's fixture, and specifically its **steady** reading — the one the
    /// decision turns on and the one no other seed can produce, since every scenario in
    /// this file seeds a single stretch and the comparison needs two.
    ///
    /// Last night ~8:30 apart for an hour; tonight ~8:24 apart, still running. The two
    /// means differ by 6 s against a 510 s reference, so `delta × 6 < previous` holds
    /// comfortably and the caption reads *about the same as your last stretch* rather
    /// than naming a direction. That is the third night of prodromal labor stated in
    /// data: a woman who has been here before, whose pattern has not changed, and whom
    /// the app can now tell so.
    ///
    /// The stretches are placed a full day apart — far past `episodeGap`, so
    /// `episodes(_:)` splits them, and far inside `stretchComparisonMaxAge`, so the
    /// older one still counts as a reference.
    private static func applySecondNight(context: ModelContext, now: Date) {
        let duration: TimeInterval = 62
        let tonightSpacing: TimeInterval = 8 * 60 + 24
        let lastNightSpacing: TimeInterval = 8 * 60 + 30
        let gaps = 7    // eight contractions each: well clear of the average's floor

        func stretch(newestStartingAgo: TimeInterval, spacing: TimeInterval) -> [Date] {
            (0...gaps).map { now.addingTimeInterval(-newestStartingAgo - Double($0) * spacing) }
        }

        // Tonight's newest ends the usual ~2 minutes ago, so the episode is live and
        // History's `offset == 0` section is the one the caption rides.
        let tonight = stretch(newestStartingAgo: 2 * 60 + duration, spacing: tonightSpacing)
        let lastNight = stretch(newestStartingAgo: 24 * 60 * 60, spacing: lastNightSpacing)

        do {
            try wipe(context)
            for point in tonight + lastNight {
                context.insert(
                    ContractionRecord(startedAt: point, endedAt: point.addingTimeInterval(duration))
                )
            }
            try context.save()
        } catch {
            assertionFailure("Demo seed failed: \(error)")
        }
    }

    /// `-seedLaborMidnight`'s arithmetic (SP-214). `episodeStart` has to fall on
    /// the calendar day *before* `now`'s — "yesterday" is a calendar concept, not
    /// "24 hours ago", the same distinction `EpisodeDay` exists to make on the
    /// rendering side — so this is built forward from a pinned start the same way
    /// `applyNearMet` is, rather than backward from `now`.
    ///
    /// 23:40 is chosen because it is exactly four textbook 5-minute intervals
    /// before midnight: the walk forward lands a contraction on the exact instant
    /// the day turns over, which is what guarantees "both sides" below without a
    /// second, edge-case-only branch.
    private static func applyMidnight(context: ModelContext, now: Date) {
        let calendar = Calendar.current
        let spacing: TimeInterval = 5 * 60
        let duration: TimeInterval = 62

        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return }
        var startComponents = calendar.dateComponents([.year, .month, .day], from: yesterday)
        startComponents.hour = 23
        startComponents.minute = 40
        guard let episodeStart = calendar.date(from: startComponents) else { return }

        do {
            try wipe(context)

            // The same "ended a couple of minutes ago" margin every other named
            // plan leaves, so the newest contraction reads as recently ended rather
            // than mid-tap — floored at today's midnight. Without the floor, a
            // launch in the first few minutes after midnight would compute a
            // margin that still lands *before* midnight, and the walk below would
            // stop short of ever crossing it: contractions on one side only, which
            // is exactly the ambiguity this scenario exists to rule out.
            let newestNoLaterThan = max(
                now.addingTimeInterval(-2 * 60 - duration),
                calendar.startOfDay(for: now)
            )
            var start = episodeStart
            while start <= newestNoLaterThan {
                context.insert(
                    ContractionRecord(
                        startedAt: start,
                        endedAt: start.addingTimeInterval(duration)
                    )
                )
                start = start.addingTimeInterval(spacing)
            }
            try context.save()
        } catch {
            assertionFailure("Demo seed failed: \(error)")
        }
    }

    private static func wipe(_ context: ModelContext) throws {
        for contraction in try context.allContractions() {
            try context.deleteContraction(id: contraction.id)
        }
    }

    /// The value that follows `flag` in `args`, if both are present — launch
    /// arguments are positional, so a flag with no following value is treated as
    /// absent rather than crashing on an out-of-bounds index.
    private static func argument(after flag: String, in args: [String]) -> String? {
        guard let index = args.firstIndex(of: flag), args.indices.contains(index + 1) else {
            return nil
        }
        return args[index + 1]
    }

    /// Decodes a `LaborSeedSnapshot` from `path` and replays it verbatim, offsets
    /// resolved against `now` — the harness's exact counterpart to the named plans
    /// above. A bad snapshot (missing file, malformed JSON, unsupported version) is
    /// a harness bug, not a runtime condition to swallow: it must be loud in DEBUG
    /// rather than silently leaving the store untouched or half-seeded.
    ///
    /// Accepts version 1 (no rule — the shape every snapshot on disk was before
    /// F-0020) and version 2 (adds `rule`). Either decodes and seeds records
    /// identically; only version 2 has anything to say about the guideline rule.
    private static func applyScenario(atPath path: String, context: ModelContext, now: Date) {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let snapshot = try JSONDecoder().decode(LaborSeedSnapshot.self, from: data)
            guard snapshot.version == 1 || snapshot.version == 2 else {
                assertionFailure("Unsupported labor seed snapshot version: \(snapshot.version)")
                return
            }

            // F-0020: the rule has to land in the persisted default *before*
            // `LaborModel` reads it, or the screen judges every rule-switch shot
            // against whatever rule the device already had. `HushlightApp.init`
            // calls `DemoSeed.applyIfRequested` before constructing `LaborModel`,
            // and `LaborModel.init` reads `GuidelineRule.persisted(in: .standard)`
            // synchronously in its own init — this write and that read are on the
            // same thread, one call apart, so ordering here is what ordering there
            // relies on. A v1 payload carries no rule and leaves the persisted one
            // untouched, exactly as it always did. An unrecognized rule string
            // falls back rather than trapping — the same choice `persisted(in:)`
            // itself makes for an unreadable stored value (F-0013).
            if let rule = snapshot.rule, let validated = GuidelineRule(rawValue: rule) {
                UserDefaults.standard.set(validated.rawValue, forKey: GuidelineRule.defaultsKey)
            }

            try wipe(context)
            for record in snapshot.records {
                context.insert(
                    ContractionRecord(
                        startedAt: now.addingTimeInterval(record.startOffsetSeconds),
                        endedAt: record.endOffsetSeconds.map { now.addingTimeInterval($0) }
                    )
                )
            }
            try context.save()
        } catch {
            assertionFailure("Labor scenario seed failed: \(error)")
        }
    }
}
#endif
