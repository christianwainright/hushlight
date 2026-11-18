import DesignKit
import SwiftUI

/// The two facts an iPhone Duo adds to the layout question (HL-061, decision 0066),
/// read through iOS 27.1's API and absent — nil, false — everywhere before it. The
/// floor stays iOS 18 (decision 0053); a device without a hinge simply never has a
/// fold.
extension GeometryProxy {
    /// Where the hinge crosses this reader's space, while it is in effect. A Duo laid
    /// flat keeps the region but reports it inactive; closed, it has none.
    var activeFold: CGRect? {
        if let simulated = SimulatedFold.current { return simulated.frame(in: self) }
        guard #available(iOS 27.1, *) else { return nil }
        return reservedRegions(kind: .division).first(where: \.isActive)?.frame
    }

    /// HL-062: how far content must stand off each edge to clear an *occlusion*
    /// region — the inner display's under-display camera. Safe-area insets do not
    /// include it. A region counts against the edge it touches, by its depth from
    /// that edge; one floating mid-screen pushes nothing, because no single inset
    /// could clear it without emptying the middle of the instrument. Zero on every
    /// device without one.
    var occlusionInsets: EdgeInsets {
        guard #available(iOS 27.1, *) else { return EdgeInsets() }
        var insets = EdgeInsets()
        let slack: CGFloat = 1
        for region in reservedRegions(kind: .occlusion) where region.isActive {
            let r = region.frame
            if r.minY <= slack { insets.top = max(insets.top, r.maxY) }
            if r.maxY >= size.height - slack { insets.bottom = max(insets.bottom, size.height - r.minY) }
            if r.minX <= slack { insets.leading = max(insets.leading, r.maxX) }
            if r.maxX >= size.width - slack { insets.trailing = max(insets.trailing, size.width - r.minX) }
        }
        return insets
    }
}

/// **Test scaffolding, not app design** (HL-061). Nothing in XCTest or `simctl` can
/// fold a simulated Duo, and Device Hub's hinge control is a window, not a command —
/// so `-simulateFold tabletop` (under `-uitesting` only) hands the layout a fold
/// where the hinge would put one: across the middle of the *screen*, not of this
/// reader, which starts below the toolbar. It proves the layout's response to a
/// fold; it cannot prove the system reports one. That half is a real device's, or
/// Device Hub's in a person's hands (decision 0066).
enum SimulatedFold: String {
    case tabletop
    case book

    static let current: SimulatedFold? = {
        guard RuntimeFlags.isUITesting else { return nil }
        let arguments = ProcessInfo.processInfo.arguments
        guard let flag = arguments.firstIndex(of: "-simulateFold"), flag + 1 < arguments.count else { return nil }
        return SimulatedFold(rawValue: arguments[flag + 1])
    }()

    func frame(in proxy: GeometryProxy) -> CGRect {
        let global = proxy.frame(in: .global)
        switch self {
        case .tabletop:
            let screenHeight = global.minY + proxy.size.height + proxy.safeAreaInsets.bottom
            return CGRect(x: 0, y: screenHeight / 2 - global.minY, width: proxy.size.width, height: 0)
        case .book:
            let screenWidth = global.minX + proxy.size.width
            return CGRect(x: screenWidth / 2 - global.minX, y: 0, width: 0, height: proxy.size.height)
        }
    }
}

extension View {
    /// Writes whether the hinge is half open — status only, never the angle. Layout
    /// changes when the pose does, not with every degree on the way there.
    func readsHalfOpen(_ isHalfOpen: Binding<Bool>) -> some View {
        modifier(HalfOpenReader(isHalfOpen: isHalfOpen))
    }
}

private struct HalfOpenReader: ViewModifier {
    @Binding var isHalfOpen: Bool

    func body(content: Content) -> some View {
        if SimulatedFold.current == .tabletop {
            content.onAppear { isHalfOpen = true }
        } else if #available(iOS 27.1, *) {
            content.onHingeChange { _, context in
                isHalfOpen = context.hinge?.status == .partiallyOpen
            }
        } else {
            content
        }
    }
}
