#if DEBUG
import SwiftUI

/// Renders a component four ways — dark and light, at default and XL Dynamic Type —
/// so the acceptance gates in spec §8 are visible in one canvas.
public struct ComponentMatrix<Content: View>: View {
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                cell("DARK · DEFAULT", scheme: .dark, size: .large)
                cell("DARK · XL", scheme: .dark, size: .accessibility3)
                cell("LIGHT · DEFAULT", scheme: .light, size: .large)
                cell("LIGHT · XL", scheme: .light, size: .accessibility3)
            }
        }
        .background(Palette.screen)
    }

    private func cell(
        _ title: String,
        scheme: ColorScheme,
        size: DynamicTypeSize
    ) -> some View {
        VStack(alignment: .leading, spacing: Metrics.space3) {
            Text(title)
                .sectionLabelText()
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Metrics.screenMargin)
        .background(Palette.screen)
        .environment(\.colorScheme, scheme)
        .environment(\.dynamicTypeSize, size)
        .tint(Palette.tint)
    }
}
#endif
