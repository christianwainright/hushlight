import SwiftUI
import Testing
import UIKit
@testable import DesignKit

/// Backlog SP-019. The display type roles scale via `@ScaledMetric` but do not *declare*
/// Dynamic Type support, so the accessibility audit flags them (decision 0008).
/// `Font.custom(_:size:relativeTo:)` would declare it — but only if a monospaced face
/// name actually resolves on iOS 27. Checked rather than assumed.
@Suite("Font resolution")
struct FontResolutionTests {
    /// The PostScript names a `Font.custom` path would need.
    private static let candidates = [
        "SFMono-Regular", "SFMono-Bold", "SFMono-Semibold",
        ".SFUIMonospaced-Regular", "Menlo-Regular",
    ]

    @Test func recordWhichMonospacedFacesResolveByName() {
        var resolved: [String] = []
        for name in Self.candidates where UIFont(name: name, size: 17) != nil {
            resolved.append(name)
        }
        // Not an assertion about which ones exist — an observation, printed so SP-019 can
        // be decided on evidence. Menlo is the fallback that has always shipped.
        print("SP-019 resolvable monospaced faces: \(resolved)")
        #expect(!resolved.isEmpty, "no monospaced face resolves by name at all")
    }

    /// The system monospaced font is always available via the design parameter, which is
    /// what `DataTextRole` already uses. The question SP-019 asks is only whether a
    /// *named* face exists so `relativeTo:` can be applied.
    @Test func theSystemMonospacedDesignIsAlwaysAvailable() {
        let descriptor = UIFont.systemFont(ofSize: 17).fontDescriptor
            .withDesign(.monospaced)
        #expect(descriptor != nil)
    }
}
