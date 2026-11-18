import Foundation
import os

/// Diagnostic breadcrumbs for the paths that have failed before (decision 0029 §3):
/// Live Activity lifecycle, store open and store writes, intent execution. They
/// exist so a sysdiagnose or a targeted question is answerable —
/// `log show --predicate 'subsystem == "net.wainright.hushlight"'` — after a night
/// the app got something wrong.
///
/// The privacy rule — state transitions, never her figures — is enforced by the
/// shape of this API rather than by discipline: the only things a call site can
/// pass are a case of the closed `Event` enum and an error reduced to its *type*
/// name. No string, date, or number parameter exists, so a contraction figure
/// cannot reach the log by construction. `scripts/lint-logging.sh` keeps this file
/// the only one in shipped code that talks to the logger, and `BreadcrumbTests`
/// audit the vocabulary itself.
public enum Breadcrumb {
    public static let subsystem = "net.wainright.hushlight"

    public enum Category: String {
        case store
        case liveActivity
        case intent
    }

    /// Every line the app can ever log. Closed and figure-free on purpose: these
    /// raw values are the entire log vocabulary, and the tests assert none of them
    /// carries a digit or a format specifier.
    public enum Event: String, CaseIterable, Sendable {
        case storeOpened
        case storeOpenFailed
        case storeReloadFailed
        case tapSaveFailed
        case deleteFailed
        case undoFailed
        case mergeFailed
        case clearAllFailed
        case activityRequested
        case activityRequestFailed
        case activityUpdated
        case activityEnded
        case activityReplaced
        case intentBegan
        case intentCompleted
        case intentFailed
        case intentRefusedOutsideApp

        var category: Category {
            switch self {
            case .storeOpened, .storeOpenFailed, .storeReloadFailed,
                 .tapSaveFailed, .deleteFailed, .undoFailed, .mergeFailed, .clearAllFailed:
                .store
            case .activityRequested, .activityRequestFailed, .activityUpdated,
                 .activityEnded, .activityReplaced:
                .liveActivity
            case .intentBegan, .intentCompleted, .intentFailed, .intentRefusedOutsideApp:
                .intent
            }
        }
    }

    /// Events are rare — failed saves, activities turning over, intent runs — so a
    /// `Logger` per call costs nothing measurable; the OS caches the log handle.
    /// `.public` is safe precisely because the vocabulary is closed: there is
    /// nothing here the redaction default would be protecting.
    public static func log(_ event: Event, error: (any Error)? = nil) {
        let logger = Logger(subsystem: subsystem, category: event.category.rawValue)
        if let error {
            // The type name only. An error's description can interpolate file
            // paths or whatever a framework felt like including, and none of that
            // has been audited; the type is a compile-time fact.
            let errorType = String(describing: type(of: error))
            logger.error("\(event.rawValue, privacy: .public) \(errorType, privacy: .public)")
        } else {
            logger.log("\(event.rawValue, privacy: .public)")
        }
    }
}
