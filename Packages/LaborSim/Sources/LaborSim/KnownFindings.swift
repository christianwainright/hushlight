import Foundation

// The valve between "the suite is green" and "the harness found something."
//
// A QA harness that fails the build on every defect it discovers is a harness that
// gets switched off within a week — and this one is pointed at shipping code whose
// known trade-offs (decision 0021's accepted-limitation class) are permanent by
// design. So a T0 violation is a red run *once*: the first time it is seen. After a
// human has triaged it into the finding register it moves here, keeps being measured
// and recorded into every results file, and stops failing the test.
//
// The ratchet that keeps this honest is `KnownFindingsTests`: an entry that no longer
// matches anything is itself a failure. A fix that removes a violation must remove
// its entry in the same commit, so the registry can never silently accumulate
// permission to be wrong about things that are already right.

/// One already-triaged T0 violation.
public struct KnownFinding: Sendable, Equatable {
    /// Which leg of the harness sees it. A store-only divergence registered against
    /// the pure leg would go stale the moment the pure sweep stopped matching it, and
    /// the staleness test would report the wrong thing.
    public enum Leg: String, Sendable, Codable, CaseIterable {
        case pure, store, model, agreement
    }

    /// Matched against `ScenarioManifest.id`. `*` is the only wildcard and may appear
    /// at either end or both — deliberately not a regex: these patterns are read
    /// during triage by people reasoning about which scenarios are covered, and a
    /// regex is a language you have to be fluent in to audit.
    public var scenarioIdPattern: String
    public var checkId: String

    /// The finding register's F-number. `F-TBD-n` while a run is still ahead of
    /// triage — the harness assigns the placeholder, a human assigns the real one.
    public var findingRef: String
    public var leg: Leg

    /// One line, mechanical: what actually happens, not how bad it is. Severity is
    /// the register's job (RUBRIC §3), not this file's.
    public var mechanism: String

    public init(
        scenarioIdPattern: String,
        checkId: String,
        findingRef: String,
        leg: Leg,
        mechanism: String
    ) {
        self.scenarioIdPattern = scenarioIdPattern
        self.checkId = checkId
        self.findingRef = findingRef
        self.leg = leg
        self.mechanism = mechanism
    }
}

public enum KnownFindings {

    /// **The registry.** Every entry here is a violation the harness has already
    /// found and a human has already looked at.
    ///
    /// Empty, and that is the ratchet working rather than a suite with nothing to
    /// say. The first corpus run registered three: F-0001 (undo restoring a second
    /// running record), F-0002 (`isRunning` and `runningSince` disagreeing after a
    /// backward clock set) and F-0003 (the stop tap that became a start tap, taking
    /// half the timeline with it). SP-194 fixed all three, so their entries left in
    /// the same change — `KnownFindingsTests` would otherwise fail them as stale,
    /// which is exactly what it is for. Their catching scenarios now live on as
    /// frozen pins under `Tests/LaborSimTests/Fixtures/Pins`.
    public static let registry: [KnownFinding] = []

    /// The entry covering this violation, if there is one.
    public static func match(scenarioId: String, checkId: String, leg: KnownFinding.Leg) -> KnownFinding? {
        registry.first {
            $0.checkId == checkId && $0.leg == leg && matches($0.scenarioIdPattern, scenarioId)
        }
    }

    /// Glob matching over the one wildcard this file allows. Empty segments from a
    /// leading or trailing `*` fall out of the loop naturally, so `*x*`, `x*`, `*x`
    /// and `x` all take the same path.
    public static func matches(_ pattern: String, _ id: String) -> Bool {
        guard pattern.contains("*") else { return pattern == id }
        let segments = pattern.components(separatedBy: "*")
        var remainder = Substring(id)

        for (index, segment) in segments.enumerated() where !segment.isEmpty {
            let anchoredToStart = index == 0
            let anchoredToEnd = index == segments.count - 1

            if anchoredToStart {
                guard remainder.hasPrefix(segment) else { return false }
                remainder = remainder.dropFirst(segment.count)
                continue
            }
            if anchoredToEnd {
                return remainder.hasSuffix(segment)
            }
            guard let found = remainder.range(of: segment) else { return false }
            remainder = remainder[found.upperBound...]
        }
        return true
    }
}
