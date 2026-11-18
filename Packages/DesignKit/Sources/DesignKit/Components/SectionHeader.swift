import SwiftUI

/// A full-bleed hairline rule with mono-caps labels beneath it. Sections in this
/// app are ruled, not carded — raised surfaces are reserved for tappable
/// containers and the share-safe summary (spec §5).
public struct SectionHeader: View {
    private let label: String
    private let trailing: String?
    private let onFill: Bool

    /// - Parameter onFill: `true` when this header sits on `Palette.inputFill`
    ///   rather than the room — e.g. Guidance's "Call right away" card. See
    ///   `sectionLabelText(onFill:)` (HL-019).
    public init(label: String, trailing: String? = nil, onFill: Bool = false) {
        self.label = label
        self.trailing = trailing
        self.onFill = onFill
    }

    public var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Palette.hairline)
                .frame(height: Metrics.hairline)

            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .sectionLabelText(onFill: onFill)

                if let trailing {
                    Spacer(minLength: Metrics.space3)
                    Text(trailing)
                        .sectionLabelText(onFill: onFill)
                }
            }
            .padding(.top, Metrics.space3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// The full-bleed hairline used between rows inside a section.
public struct Hairline: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(height: Metrics.hairline)
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("SectionHeader") {
    ComponentMatrix {
        VStack(alignment: .leading, spacing: Metrics.space5) {
            SectionHeader(label: "Tonight")
            SectionHeader(label: "Contractions", trailing: "3")
            SectionHeader(label: "Pattern · Last Hour")
            SectionHeader(label: "History · 3 Records", trailing: "Swipe to correct")
        }
    }
}
#endif
