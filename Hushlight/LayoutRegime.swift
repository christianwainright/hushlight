import SwiftUI

/// **A stand, a hand, or a fold** (HL-058, decision 0064; HL-061, decision 0066).
/// Which of the four layouts the timer takes, chosen by the window it is in — never
/// by device model, because Split View and Stage Manager hand the app every width
/// there is, and an iPhone Duo is a compact phone and a regular slab in one evening.
///
/// * `compact` — iPhone, a closed Duo, Split View at a third, Slide Over: the single
///   column.
/// * `hand` — regular width, taller than wide: the instrument beside a live ledger of
///   the current stretch. The partner's screen.
/// * `stand` — regular width, wider than tall: the same two panes, with the leading
///   figure taken to a room's reading distance. Landscape is how a stand holds an
///   iPad, so the regime follows orientation rather than a setting.
/// * `tabletop` — a fold running across the window, half open: the count on the
///   upright half at reading distance, and the half lying flat on the nightstand is
///   the button, all of it. "Tap anywhere below the line" made literal; the line is
///   the hinge.
enum LayoutRegime: Equatable {
    case compact
    case hand
    case stand
    case tabletop

    /// - Parameters:
    ///   - fold: the active *division* reserved region in the reader's own space, or
    ///     nil — every device without a hinge, and a Duo laid flat or closed.
    ///   - isHalfOpen: the hinge reports `partiallyOpen`. Only this, never the angle:
    ///     a layout that moved with every degree would be the app performing.
    init(sizeClass: UserInterfaceSizeClass?, size: CGSize, fold: CGRect? = nil, isHalfOpen: Bool = false) {
        // A zero-height proposal mid-rotation would read as "wider than tall".
        guard size.width > 0, size.height > 0 else {
            self = .compact
            return
        }
        // Before the size class: a fold across a half-open window is the one layout
        // that is the right answer at every width the window could have.
        if isHalfOpen, let fold, Self.runsAcross(fold) {
            self = .tabletop
            return
        }
        guard sizeClass == .regular else {
            self = .compact
            return
        }
        self = size.width > size.height ? .stand : .hand
    }

    var showsLedger: Bool { self == .hand || self == .stand }

    /// The leading figure is read from across the room in a stand and from the bed
    /// on a tabletop.
    var readsAtDistance: Bool { self == .stand || self == .tabletop }

    /// The ledger is the quieter pane: a third-and-a-bit of the window, never so
    /// narrow that a History row has to stack below accessibility sizes, never so
    /// wide that it competes with the instrument for the eye.
    ///
    /// Except across a fold running down the window (an open Duo held like a book):
    /// there the crease is the seam, and the ledger takes the trailing panel exactly.
    /// A row of figures broken by a hinge is worse than a ledger wider than it would
    /// choose — and the fold's frame arrives in leading-origin coordinates (the query
    /// mirrors under right-to-left), so "trailing of the fold" is one subtraction in
    /// both directions.
    func ledgerWidth(for size: CGSize, fold: CGRect? = nil) -> CGFloat {
        if let fold, !Self.runsAcross(fold), fold.maxX < size.width {
            return size.width - fold.maxX
        }
        return min(max(size.width * 0.36, 300), 440)
    }

    /// A fold wider than it is tall runs across the window — top half, bottom half.
    static func runsAcross(_ fold: CGRect) -> Bool { fold.width > fold.height }
}
