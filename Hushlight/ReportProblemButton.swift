import ActivityKit
import DesignKit
import LaborKit
import SwiftUI

/// The user-initiated report path (decision 0029 §3), the same interaction class
/// as `CallProviderButton`'s `tel:`: the OS mail app opens the draft, and she
/// sees — and can edit or delete — every line before anything is sent. This app
/// never sends an email; it drafts one.
struct ReportProblemButton: View {
    @Environment(LaborModel.self) private var model
    @Environment(\.openURL) private var openURL

    /// The OS said no — a device with no mail app (HL-057). The button used to go
    /// quiet here, which reads as broken; now the address is written out instead.
    @State private var mailRefused = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button("Report a problem") {
                if let url = ProblemReport.mailtoURL(for: context) {
                    openURL(url) { accepted in mailRefused = !accepted }
                }
            }
            .font(.prose)
            .frame(minHeight: Metrics.minimumTapTarget, alignment: .leading)
            .accessibilityLabel(String(localized: "Report a problem", comment: "VoiceOver label for the Report a problem button on the Guidance screen"))
            .accessibilityHint(String(localized: "Drafts an email you can review before sending", comment: "VoiceOver hint for the Report a problem button, stating it drafts rather than sends"))

            if mailRefused {
                HandoffFallback(
                    explanation: LocalizedStringResource("No mail app on this device. Write to:", comment: "Guidance screen: shown under Report a problem when the OS could not open a mail draft; the support address follows"),
                    value: ProblemReport.recipient,
                    copyTitle: LocalizedStringResource("Copy address", comment: "button label: copies the support email address to the clipboard"),
                    copyHint: LocalizedStringResource("Copies the address", comment: "VoiceOver hint for the Copy address button")
                )
            }
        }
    }

    /// Gathered at tap time so the coarse counts describe the moment she reports.
    /// Every field is a scalar — `ProblemReport.Context` has no parameter that
    /// could carry a contraction record, deliberately.
    private var context: ProblemReport.Context {
        let stored = DiagnosticArchive.counts()
        return ProblemReport.Context(
            appVersion: Self.appVersion,
            osVersion: Self.osVersion,
            deviceModel: Self.deviceModel,
            rule: model.rule,
            contractionCount: model.contractions.count,
            episodeCount: PatternAnalysis.episodes(model.contractions).count,
            liveActivityVisible: Activity<ContractionActivityAttributes>.activities
                .contains { $0.activityState.countsAsPresent },
            storedCrashCount: stored.crashes,
            storedHangCount: stored.hangs
        )
    }

    private static var appVersion: String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return "\(version ?? "unknown") (\(build ?? "unknown"))"
    }

    private static var osVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "iOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)" // lint-localizable:ok — "iOS" is Apple's product name, never translated
    }

    /// The hardware identifier ("iPhone17,2") via `utsname` — a plain struct read,
    /// not a required-reason API, and the form Organizer's device breakdowns use.
    private static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafeBytes(of: &systemInfo.machine) { buffer in
            String(decoding: buffer.prefix(while: { $0 != 0 }), as: UTF8.self)
        }
    }
}
