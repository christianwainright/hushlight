import Testing
@testable import LaborKit

/// The log audit 0029 §3 requires — "state transitions, never her figures" — made
/// mechanical: the event enum is the entire vocabulary the logger can emit, so
/// auditing the log means auditing these strings. `scripts/lint-logging.sh` holds
/// the other half of the guarantee (no logging outside `Breadcrumb`, no
/// interpolation beyond the closed set).
@Suite("Breadcrumbs")
struct BreadcrumbTests {
    @Test("No event name carries a digit — a name with a figure in it is a figure")
    func namesCarryNoDigits() {
        for event in Breadcrumb.Event.allCases {
            // Evaluated before the macro sees it: `#expect` decomposes a call into
            // `__checkFunctionCall`, and `contains(where:)` is `rethrows`, so the
            // expansion cannot prove the key-path argument is non-throwing and
            // demands a `try` the predicate has no use for.
            let carriesDigit = event.rawValue.contains(where: \.isNumber)
            #expect(!carriesDigit, "\(event.rawValue)")
        }
    }

    @Test("No event name carries a format specifier or interpolation")
    func namesCarryNoSpecifiers() {
        for event in Breadcrumb.Event.allCases {
            #expect(!event.rawValue.contains("%"), "\(event.rawValue)")
            #expect(!event.rawValue.contains("\\("), "\(event.rawValue)")
        }
    }

    /// One predicate answers a sysdiagnose, so the subsystem must be the app's
    /// bundle identifier and must never drift from it.
    @Test func subsystemIsTheBundleIdentifier() {
        #expect(Breadcrumb.subsystem == "net.wainright.hushlight")
    }

    /// Diagnostics that can themselves fail mid-labor would be worse than none:
    /// logging must be safe with and without an error attached.
    @Test func loggingNeverThrowsOrTraps() {
        struct Fixture: Error {}
        Breadcrumb.log(.storeOpened)
        Breadcrumb.log(.storeReloadFailed, error: Fixture())
    }
}
