import Foundation
import LaborKit
import MetricKit

/// Receives MetricKit's crash and hang diagnostics and keeps the last few
/// summaries on device (decision 0029 §3). The OS delivers payloads on its own
/// queue, at most about once a day, usually on the launch after the incident;
/// `HushlightApp` holds one instance for the app's lifetime.
///
/// Nothing here transmits. Summaries land in `DiagnosticArchive` — local
/// defaults — and the only reader is the problem-report email's coarse counts,
/// so "did it crash for you?" has an answer she can read out if she writes in.
final class CrashDiagnostics: NSObject, MXMetricManagerSubscriber {
    override init() {
        super.init()
        MXMetricManager.shared.add(self)
    }

    deinit {
        MXMetricManager.shared.remove(self)
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            for crash in payload.crashDiagnostics ?? [] {
                DiagnosticArchive.record(DiagnosticSummary(
                    kind: .crash,
                    date: payload.timeStampEnd,
                    appVersion: crash.applicationVersion,
                    osVersion: crash.metaData.osVersion,
                    detail: Self.detail(for: crash)
                ))
            }
            for hang in payload.hangDiagnostics ?? [] {
                DiagnosticArchive.record(DiagnosticSummary(
                    kind: .hang,
                    date: payload.timeStampEnd,
                    appVersion: hang.applicationVersion,
                    osVersion: hang.metaData.osVersion,
                    detail: Self.detail(for: hang)
                ))
            }
        }
    }

    /// The coarse identifying facts only — enough to match the crash in Organizer
    /// later, never a stack.
    private static func detail(for crash: MXCrashDiagnostic) -> String {
        var parts: [String] = []
        if let exceptionType = crash.exceptionType {
            parts.append("exception \(exceptionType)")
        }
        if let signal = crash.signal {
            parts.append("signal \(signal)")
        }
        return parts.isEmpty ? "crash" : parts.joined(separator: " · ")
    }

    private static func detail(for hang: MXHangDiagnostic) -> String {
        let seconds = hang.hangDuration.converted(to: .seconds).value
        return "hang of about \(Int(seconds.rounded())) seconds"
    }
}
