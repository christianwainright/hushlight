import SwiftUI

/// Every tappable element in this app reads as a button. Four weights only:
/// filled for the primary action, tinted for the secondary, bordered for links
/// and tertiary actions (spec §3), neutral for the quiet ones.
public struct CapsuleButtonStyle: ButtonStyle {
    public enum Weight {
        /// Primary — tint-filled, onEmber label.
        case filled
        /// Secondary — tint-tinted background, tint label.
        case tinted
        /// Tertiary and links — hairline border, tint label, no fill.
        case bordered
        /// Neutral tertiary — a low-emphasis chip with no semantic weight.
        case neutral
    }

    private let weight: Weight
    private let role: DataTextRole?

    /// - Parameter role: Set when the label should render as mono caps rather than
    ///   prose, e.g. a "SEE WHAT LEAVES YOUR PHONE" privacy link. A trailing
    ///   disclosure chevron on a label like that belongs on `chevron.forward`
    ///   (HL-009) — never baked into the string as a literal `›`, which does not
    ///   mirror under RTL the way the SF Symbol's direction-aware pair does.
    public init(_ weight: Weight, role: DataTextRole? = nil) {
        self.weight = weight
        self.role = role
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Tinted and bordered labels use the darkened text variant: plain `systemBlue` on
    /// a 15%-blue fill is 2.99:1 in light appearance, which the accessibility audit
    /// failed on every RPE button. The fill and border keep the undarkened tint
    /// (decision 0008).
    private var foreground: Color {
        switch weight {
        case .filled: Palette.onEmber
        case .tinted, .bordered: Palette.tintText
        case .neutral: Palette.secondaryText
        }
    }

    private var background: Color {
        switch weight {
        case .filled: Palette.tint
        case .tinted: Palette.tintFill
        case .bordered: .clear
        case .neutral: Palette.pendingFill
        }
    }

    private var border: Color {
        switch weight {
        case .bordered: Palette.tintBorder
        case .filled, .tinted, .neutral: .clear
        }
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(LabelFont(role: role))
            .foregroundStyle(foreground)
            .padding(.horizontal, Metrics.space4)
            .padding(.vertical, Metrics.space3)
            .frame(minHeight: Metrics.minimumTapTarget)
            .background(background, in: .capsule)
            .overlay(Capsule().strokeBorder(border, lineWidth: 1))
            // Reduce Motion swaps the scale for an opacity change (spec §7).
            .scaleEffect(!reduceMotion && configuration.isPressed ? Metrics.pressedScale : 1)
            .opacity(reduceMotion && configuration.isPressed ? Metrics.pressedOpacity : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
            .contentShape(.capsule)
            // A pointer on iPad (HL-058b): the system's own lift, nothing drawn.
            .hoverEffect(.automatic)
    }
}

/// Applies the mono role when one is given, and prose weight otherwise.
private struct LabelFont: ViewModifier {
    let role: DataTextRole?

    func body(content: Content) -> some View {
        if let role {
            content.dataText(role)
        } else {
            content.font(.prose.weight(.semibold))
        }
    }
}

extension ButtonStyle where Self == CapsuleButtonStyle {
    public static var capsuleFilled: CapsuleButtonStyle { CapsuleButtonStyle(.filled) }
    public static var capsuleTinted: CapsuleButtonStyle { CapsuleButtonStyle(.tinted) }
    public static var capsuleBordered: CapsuleButtonStyle { CapsuleButtonStyle(.bordered) }
    public static var capsuleNeutral: CapsuleButtonStyle { CapsuleButtonStyle(.neutral) }
    /// Bordered capsule with a mono-caps label — the privacy line and the
    /// guidance links.
    public static var capsuleLink: CapsuleButtonStyle {
        CapsuleButtonStyle(.bordered, role: .label)
    }
}

#if DEBUG
#Preview("CapsuleButtonStyle") {
    ComponentMatrix {
        VStack(alignment: .leading, spacing: Metrics.space3) {
            Button("Call provider") {}.buttonStyle(.capsuleFilled)
            Button("Change guideline") {}.buttonStyle(.capsuleTinted)
            // HL-009: a disclosure chevron is `chevron.forward`, never a baked `›`
            // — see `init(role:)`'s doc comment. Split into a label closure so the
            // arrow is its own direction-aware glyph rather than a character
            // riding inside the button's title.
            Button {} label: { HStack(spacing: Metrics.space1) { Text("Guidance"); Image(systemName: "chevron.forward").imageScale(.small) } }
                .buttonStyle(.capsuleBordered)
            Button("Tonight") {}.buttonStyle(.capsuleNeutral)
            Button {} label: { HStack(spacing: Metrics.space1) { Text("SEE WHAT LEAVES YOUR PHONE"); Image(systemName: "chevron.forward").imageScale(.small) } }
                .buttonStyle(.capsuleLink)
        }
    }
}
#endif
